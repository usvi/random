<?php

$wake_interface = "enp2s0";
$fping_wait_msecs = "150";


//
// Wakes local network computers based on info from /etc/ethers
//
// Ok the deal is this.
// 1. Install fping and etherwake
// 2. Make etherwake setuid root (chmod u+x usually)
// 3. Make /etc/ethers like this:
//#VIERA_TV
//20:C6:EB:A3:54:C0 172.16.8.194
//##PS3_LAN
//##F8:D0:AC:F9:14:59 172.16.8.193
// Actual comment lines = ##
// Name lines = #
// Regular ether lines MAC IP
// This probably breaks somehow if there are empty lines.



// Do the wake on here

if (isset($_POST['target']))
{
    $command = "/sbin/etherwake -i ". $wake_interface . " " . $_POST['target'];
    exec($command);
    header("Location: " . $_SERVER['REQUEST_URI']);
}
    


$lines = file("/etc/ethers");
$hosts = array();



for ($i = 1; $i < count($lines); $i++)
{
    if (strpos($lines[$i], "#") !== 0 && strpos($lines[$i - 1], "##") !== 0)
    {
        $name = trim($lines[$i - 1]);
        $name = substr($name, 1);
        $temp = explode(" ", trim($lines[$i]));
        $mac = trim($temp[0]);
        $ip = trim($temp[1]);

        $element = array();
        $element["name"] = $name;
        $element["mac"] = $mac;
        $element["ip"] = $ip;

        $hosts[count($hosts)] = $element;			
    }
}



for ($i = 0; $i < count($hosts); $i++)
{
	//print($value["name"] . "<br>");
	// fping -4 -t 150 -r 0 172.16.8.181

	$command = "fping -4 -t " . $fping_wait_msecs . " -r 0 " . $hosts[$i]["ip"];
	$output = 4;
	$code = 4;
	
	exec($command, $output, $code);

	if ($code === 0)
	{
		$hosts[$i]["online"] = 1;
	}
	else
	{
		$hosts[$i]["online"] = 0;
	}
}


// Just printing these with php because emacs is acting stupid.
print("<html>\n" .
"<head><title>Management</title></head>\n" . 
"\n\n" .
"<table border=\"3\">\n" .
"<tr>\n" .
"<th>Name</th>\n" .
"<th>Status</th>\n" .
"<th></th>\n" .
"<th>MAC</th>\n" .
"<th>IP</th>\n" .
"</tr>\n");



for ($i = 0; $i < count($hosts); $i++)
{
    print("<tr>\n");

    print("<td>" . $hosts[$i]["name"] . "</td>\n");

    if ($hosts[$i]["online"] === 1)
    {
        print("<td><b><font color=\"green\">ONLINE</font></b></td>\n");
    }
    else
    {
        print("<td><b><font color=\"red\">OFFLINE</font></b></td>\n");
    }
    print("<td><form style=\"margin-bottom:0;\" action=\"\" method=\"post\"><input type=\"hidden\" name=\"target\" value=\"" . $hosts[$i]["mac"] . "\"><input type=\"submit\" name=\"sendwol\" value=\"Send Wake-Up\" /></form></td>\n");

    print("<td>" . $hosts[$i]["mac"] . "</td>\n");
    print("<td>" . $hosts[$i]["ip"] . "</td>\n");
    
    print("</tr>\n");
}

print("</table>\n" .
      "</html>\n");

?>
