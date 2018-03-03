<?php
include "mysql_compat.php";

function abort($error) {
    exit("<JSON>" . json_encode(array('error' => $error)));
}

function dbabort() {
    global $link;
    $backtrace = debug_backtrace();
    $line = $backtrace[0]['line'];
    $errstr = (isset($link) && $link != false) ? mysql_error($link) : mysql_error();
    abort("database error (line " . $line . "): " . $errstr);
}

$dbname = "loulabelle_playground";
$usrname = $dbname;
$usrpass = "";
if (file_exists('serverdb2.php'))
    include "serverdb2.php";

$link = mysql_pconnect("localhost", $usrname, $usrpass) or dbabort();
mysql_select_db($dbname, $link) or dbabort();

$operation = preg_replace("/\W+/", "", $_POST["op"]);
$folder = mysql_real_escape_string(preg_replace("/\W+/", "?", $_POST["folder"]), $link);

if ($operation == "list_folders")
    $response = op_list_folders($link, $folder);
elseif ($operation == "list_files")
    $response = op_list_files($link, $folder);
elseif ($operation == "read_file")
    $response = op_read_file($link, $folder);
elseif ($operation == "new_folder")
    $response = op_new_folder($link, $folder);
elseif ($operation == "save_file")
    $response = op_save_file($link, $folder);
elseif ($operation == "change_password")
    $response = op_change_password($link, $folder);
else
    $response = "unknown request " . $operation;

echo "<JSON>" . json_encode($response);

function op_list_folders($link, $folder) {

    $sql = "
        select folder_name from loulabelle_folders
        where folder_name like '" . $folder . "%'
        order by public desc, folder_name";
    $result = mysql_query($sql, $link) or dbabort();

    $num_rows = mysql_num_rows($result);
    $response = array('n' => $num_rows);
    for ($row_num = 0; $row_num < $num_rows; $row_num++) {
        $row = mysql_fetch_assoc($result);
        $response[$row_num + 1] = $row;
    }

    return $response;
}

function op_list_files($link, $folder) {

    $sql = "
        select file_name from loulabelle_files
        where folder_name = '" . $folder . "'
        order by file_name";
    $result = mysql_query($sql, $link) or dbabort();

    $num_rows = mysql_num_rows($result);
    $response = array('n' => $num_rows);
    for ($row_num = 0; $row_num < $num_rows; $row_num++) {
        $row = mysql_fetch_assoc($result);
        $response[$row_num + 1] = $row;
    }

    return $response;
}

function op_read_file($link, $folder) {

    header('Access-Control-Allow-Origin: *');

    $file = mysql_real_escape_string(preg_replace("/\W+/", "?", $_POST["file"]), $link);

    $sql = "
        select folder_name, file_name, source_text from loulabelle_files
        where folder_name = '" . $folder . "'
          and file_name = '" . $file . "'";
    $result = mysql_query($sql, $link) or dbabort();

    if (mysql_num_rows($result) == 0) {

        $sql = "
            select folder_name from loulabelle_folders
            where folder_name = '" . $folder . "'";
        $result = mysql_query($sql, $link) or dbabort();

        if (mysql_num_rows($result) == 0)
            abort('Folder not found: ' . $folder);
        else
            abort('File not found: ' . $file);
    }

    return mysql_fetch_assoc($result);
}

function op_new_folder($link, $folder) {

    if ($folder != $_POST["folder"] || strlen($folder) < 1 || strlen($folder) > 99)
        abort('Invalid folder name');

    $password = $_POST["password"];
    if (! preg_match("/^[a-zA-Z0-9!@#$%^&*();:<>,.?]{1,32}$/", $password))
        abort('Invalid password');
    $password = password_hash($password, PASSWORD_DEFAULT);
    $password = mysql_real_escape_string($password, $link);

    $sql = "
        insert into loulabelle_folders (folder_name, password)
        values ('" . $folder . "','" . $password . "')";
    $result = mysql_query($sql, $link) or dbabort();

    return array('ok' => 'ok');
}

function op_save_file($link, $folder) {

    $file = mysql_real_escape_string(preg_replace("/\W+/", "?", $_POST["file"]), $link);
    if ($file != $_POST["file"] || strlen($file) < 1 || strlen($file) > 99)
        abort('Invalid file name');

    $sql = "
        select password from loulabelle_folders
        where folder_name = '" . $folder . "'";
    $result = mysql_query($sql, $link) or dbabort();

    if (mysql_num_rows($result) != 1)
        abort('Folder does not exist');

    $row = mysql_fetch_assoc($result);
    if (! password_verify($_POST["password"], $row["password"]))
        abort('Wrong password for folder');

    $source = mysql_real_escape_string($_POST["source"], $link);

    if ($source == "") {

        dbclean($link);

        $sql = "
            delete from loulabelle_files
            where folder_name = '" . $folder . "'
              and file_name = '" . $file . "'";

    } else {

        $sql = "
            insert into loulabelle_files (folder_name, file_name, source_text)
            values ('" . $folder . "','" . $file . "', '" . $source . "')
            on duplicate key update source_text = '" . $source . "'";
    }

    $result = mysql_query($sql, $link) or dbabort();

    return array('ok' => 'ok');
}

function op_change_password($link, $folder) {

    $sql = "
        select password from loulabelle_folders
        where folder_name = '" . $folder . "'";
    $result = mysql_query($sql, $link) or dbabort();

    if (mysql_num_rows($result) != 1)
        abort('Folder does not exist');

    $row = mysql_fetch_assoc($result);
    if (! password_verify($_POST["password"], $row["password"]))
        abort('Wrong password for folder');

    $password = $_POST["password2"];
    if (! preg_match("/^[a-zA-Z0-9!@#$%^&*();:<>,.?]{1,32}$/", $password))
        abort('Invalid new password');
    $password = password_hash($password, PASSWORD_DEFAULT);
    $password = mysql_real_escape_string($password, $link);

    $sql = "
        update loulabelle_folders
        set password = '" . $password . "'
        where folder_name = '" . $folder . "'";
    $result = mysql_query($sql, $link) or dbabort();

    return array('ok' => 'ok');
}

function dbclean($link) {

    $sql = "delete from loulabelle_folders
            where timestampdiff(
                    minute,update_time,current_timestamp) > 0
            and folder_name not in (
                select folder_name
                from loulabelle_files
                where loulabelle_folders.folder_name =
                            loulabelle_files.folder_name)";
    mysql_query($sql, $link);
}

?>
