<?php

define('ADMIN_USERNAME','whoareyou'); 	// Admin Username
define('ADMIN_PASSWORD','callmejwkj');  	// Admin Password

if (!isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW']) ||
           $_SERVER['PHP_AUTH_USER'] != ADMIN_USERNAME ||$_SERVER['PHP_AUTH_PW'] != ADMIN_PASSWORD) {
			   
	//header("WWW-Authenticate: Basic realm=\"Memcache Login\"");
	//header("HTTP/1.0 401 Unauthorized");

}
?>

<html>
	<head>
		<title>清除memcached缓存</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	</head>
	<body>
		<form action="" method="post">
			<h2>一行代表一篇文章</h2>
			清除缓存:
			<textarea style="width:100%; height:200px;" placeholder='样式：www.easyzw.com/news/201608/533414.html' name="key" ></textarea>
			<p><input type="submit" value="清除缓存" style="width:100%; height:50px; font-size:24px;"/></p>
		</form>
	</body>
</html>

<?php
if($_POST){
	//实例化
        $memc = new Memcached();
        //连接服务器
        $memc->addServer("127.0.0.1",11211);
	//换行处理
	$keys = explode("\n",$_POST['key']);
	foreach($keys as $val){
		$md5Key = MD5(trim($val));
		$res = $memc->delete($md5Key);
		if(!$res){
			$errReturn .= $val."地址出错<br />";
		}	
	}
	if($errReturn){
		echo $errReturn;	
	}else{
		echo '缓存已清除';
	}
		
}

?>
