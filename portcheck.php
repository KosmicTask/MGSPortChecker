<?php 

//
// request url pattern:
//
// portchecker.mysite.com/portchecker.php?p=1234&t=5
//
// query keys:
// p: port to be queried
// t: port query timeout (optional)
//

// request address
$host = $_SERVER['REMOTE_ADDR'];

// get port to be queried
$port = (int)$_GET['p'];

// get timeout
$timeout = (int)$_GET['t'];
if ($timeout <= 0) {
  $timeout = 10;
}
if ($timeout > 20) {
  $timeout = 20;
}

$status = 0;

// open socket on port
if ($port > 0 && $timeout > 0) {
  $connection = @fsockopen($host, $port, $errno, $errstr, $timeout);
  if (is_resource($connection)) {
    $status = 1;
    fclose($connection);
  }
}

// return host IP and port status
echo $host." ".$status;
?>