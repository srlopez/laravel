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
            @foreach($users as $user)
            <tr>
            <td>{{$user->name}} </td>
            <td>{{$user->email}} </td>
            </tr>
            @endforeach
        </tbody>
    </table>
    </body>
</html>
