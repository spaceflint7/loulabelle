<?php

/**
 * replacement for all mysql functions
 * https://gist.github.com/rubo77/1db052edd8d723b59c79790b42635f1e
 */

if (!function_exists("mysql_connect")){

    /* warning: fatal error "cannot redeclare" if a function was disabled in php.ini with disable_functions:
    disable_functions =mysql_connect,mysql_pconnect,mysql_select_db,mysql_ping,mysql_query,mysql_fetch_assoc,mysql_num_rows,mysql_fetch_array,mysql_error,mysql_insert_id,mysql_close,mysql_real_escape_string,mysql_data_seek,mysql_result
    */

    function mysql_error($link = NULL) { return $link ? mysqli_error($link) : mysqli_connect_error(); }

    function mysql_connect($host, $username, $password) { return @mysqli_connect($host, $username, $password); }

    function mysql_pconnect($host, $username, $password) { return @mysqli_connect("p:" . $host, $username, $password); }

    function mysql_close($link) { return mysqli_close($link); }

    function mysql_select_db($dbname, $link) { return mysqli_select_db($link, $dbname); }

    function mysql_ping($link) { return mysqli_ping($link); }

    function mysql_query($query, $link) { return mysqli_query($link, $query); }

    function mysql_num_rows($result) { return mysqli_num_rows($result); }

    function mysql_num_fields($result) { return mysqli_num_fields($result); }

    function mysql_fetch_row($result) { return mysqli_fetch_row($result); }

    function mysql_fetch_assoc($result) { return mysqli_fetch_assoc($result); }

    function mysql_real_escape_string($str, $link) { return mysqli_real_escape_string($link, $str); }






    function mysql_affected_rows($e=NULL){
        return mysqli_affected_rows ($e );
    }
    function mysql_insert_id($cnx){
        return mysqli_insert_id ( $cnx );
    }
    function mysql_data_seek($re,$row){
        return mysqli_data_seek($re,$row);
    }

    function mysql_result($res,$row=0,$col=0){
        $numrows = mysqli_num_rows($res);
        if ($numrows && $row <= ($numrows-1) && $row >=0){
            mysqli_data_seek($res,$row);
            $resrow = (is_numeric($col)) ? mysqli_fetch_row($res) : mysqli_fetch_assoc($res);
            if (isset($resrow[$col])){
                return $resrow[$col];
            }
        }
        return false;
    }
}