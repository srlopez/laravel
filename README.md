# CONTENERIXANDO LARAVEL

## En desarrollo
Objetivo crear un contenedor con todo lo necesario de laravel, pero el directorio de la aplicación que esté en local.

### Creación de una IMAGEN con LARAVEL 9
En el disrectorio local src contendrá el código de la aplicación. Ya que esta imagen quiero que sea independiente de cualquier aplicación. Y lanzamos un BASH desde la IMAGEN que queremos tomar de partida
```dos
mkdir src
docker run -it --rm --name laravel ubuntu
```
En el container, instalamos todo lo necesario para que funcione Laravel (he tomado prestado parte de Laravel Sail)
```bash
export DEBIAN_FRONTEND=noninteractive
export TZ=Europe/Madrid
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

apt update 
apt install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils 
curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /usr/share/keyrings/ppa_ondrej_php.gpg > /dev/null 
echo "deb [signed-by=/usr/share/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list 
apt update 
apt install -y php8.2-cli php8.2-dev \
       php8.2-pgsql php8.2-sqlite3 php8.2-gd \
       php8.2-curl  \
       php8.2-imap php8.2-mysql php8.2-mbstring \
       php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap \
       php8.2-intl php8.2-readline \
       php8.2-ldap \
       php8.2-msgpack php8.2-igbinary php8.2-redis php8.2-swoole \
       php8.2-memcached php8.2-pcov php8.2-xdebug 
php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer 
curl -sLS https://deb.nodesource.com/setup_18.x | bash - 
apt install -y nodejs 
npm install -g npm 
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn.gpg >/dev/null 
echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list 
apt update 
apt install -y yarn 
apt install -y mysql-client 
apt install -y apache2 libapache2-mod-php
apt -y autoremove 
apt clean 
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
composer --version
```
En otra consola fiajmos la imagen y una vez hecho, entramos a crear una aplicación desde dentro
```dos
docker commit laravel laravel:dev
docker stop laravel
docker images -a
docker run -it --rm -p 8000:8000 -v %CD%\src:/src -w /src laravel:dev bash
```
En el nuevo container creamos y lanzamos la aplicación de ejemplo
```bash
composer create-project laravel/laravel example-app
cd example-app
php artisan serve --host 0.0.0.0 --port 8000
```
`explorer http://localhost:8000` debería mostrar la página de Bienvenida

Para enlazar con BBDD, lanzamos mysql, y de nuevo el entorno laravel enlazado a la BBDD
```dos
docker run -d --rm --name db -e MYSQL_DATABASE=laravel -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -v %CD%\data:/var/lib/mysql mysql
docker run -d --rm --link db -v %CD%\src:/src -w /src laravel:dev bash
```
Modificamos dentro del container lo minimo necesario para que la aplicación conecte (.env),  creamos unos datos (Users con Tinker) y los presentamos (welcome.blade.php y web.php)
```bash 
cd example-app
sed -i 's/DB_HOST=127.0.0.1/DB_HOST=db/g' .env
grep DB_HOST .env

php artisan migrate 
php artisan tinker --execute="User::factory()->count(9)->create();"
sed -i "s@'welcome'@'welcome', array('users' => App\\\Models\\\User::all())@g" routes/web.php
cat  routes/web.php

cat <<EOF >resources/views/welcome.blade.php
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
<style>
<style>
table {   height: 100%;  }

#center {
    font-family: "Lucida Console", "Lucida Sans Typewriter", monaco, "Bitstream Vera Sans Mono", monospace; font-size: 24px; font-style: normal; font-variant
: normal; font-weight: 400; line-height: 23px;
  margin: 0 auto;
  padding: 10px;
  text-align: left; /*center;*/
  width: 800px; /*100%;*/
}

</style>
    </head>
    <body class="antialiased">
    <table id=center>
        <thead>
        <th>Username</th>
        <th>Email</th>
        </thead>
        <tbody>
            @foreach(\$users as \$user)
            <tr>
            <td>{{\$user->name}} </td>
            <td>{{\$user->email}} </td>
            </tr>
            @endforeach
        </tbody>
    </table>
    </body>
</html>
EOF
cat resources/views/welcome.blade.php
exit
```
Una vez modificado todo, he preferido salir y lanzarlo desde comando
```
docker run -it --rm -p 8000:8000 --link db -v %CD%\src:/src -w /src/example-app laravel:dev php artisan serve --host 0.0.0.0 --port 8000
```
Con `explorer http://localhost:8000` debería mostrar los usuarios generados.

## En Producción
Debemos poner un **servidor web** que exponga la aplicación.
Tambien es conveniente generar una **imagen de la aplicación** y **componer todos los servicios** que vamos a usar
### APACHE
Establecemos los permisos para que apache funcione.
```dos
docker run -it --rm -v %CD%\src:/src -w /src laravel:dev bash -c "chmod -R 775 example-app/ && chown -R www-data:www-data example-app/"
```
y lanzamos la aplicación con el virtualhost que hemos configurado
```
docker run -d --rm -p 80:80 --link db -v %CD%\src:/src -v %CD%\000-default.conf:/etc/apache2/sites-available/000-default.conf:ro -w /src laravel:dev /usr/sbin/apache2ctl -D FOREGROUND
```
Con `explorer http://localhost:8000` debería mostrar los usuarios generados.

### IMAGEN
En el `Dokerfile` se realizan los mismos pasos que hicimos para crear la imagen para desarrollo, y además copiamos la aplicación y las configuraciones que necesitamos.

### COMPOSER
O bien
```dos
docker build -t laravel.prod .
```
o
```
docker compose build
docker compose up
```
