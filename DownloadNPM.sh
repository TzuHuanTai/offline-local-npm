#!/bin/bash
# History:
# 	this program is to load npm all packages (name.json) file then 
# 	publish its into verdaccio(privated npm server)
# History:
# 	20181203 @Richard begin
#       20181205 @Richard 基本搞定整個流程架構，只怕npm publish那邊出事


# 讀取名單檔案，並透過npmDownload迴圈下載套件
cat ./name-small.json | awk '{

	# 提取json檔，移除特殊符號
	gsub(/"|\[|\]|\,/,"", $1);

	# 套件名稱處理並下載
	if ( length($1)>1){		
		print $1 "\t lines:" NR "\t length:" length($1);
		temp = substr($1,1,length($1)-1); 		# 移除字串尾端看不到的'\r\n'...		
		print temp "\t lines:" NR "\t length:" length(temp);		

		# 執行指令下載"最新的"版本
		downloadCmd="npmDownload -p \"" temp "\" -a -o ./";
		print downloadCmd;
		system(downloadCmd);
		print temp;

		# 重新命名downloaded folder		
		renameCmd = "mv \\\\" temp "\\\\-\\\\ " temp;
		system(renameCmd);
		
		# 取得壓縮檔名稱
		cmd="ls " temp " | head -1";
		cmd | getline tgzName;
		print tgzName;
		close(cmd);		

		# 解壓縮完休息5秒後，刪除package資料夾
		#system("sleep 5s");
		#system("rm -r " temp);				
	}
	else{
		print "====wtf====";
	}
}'

# return 0 to system
exit 0