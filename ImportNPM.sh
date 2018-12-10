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
		system("npmDownload -p \"" temp "\" -o ./");		
		print temp;

		# 重新命名downloaded folder		
		renameCmd = "mv \\\\" temp "\\\\-\\\\ " temp;
		system(renameCmd);
		
		# 取得壓縮檔名稱
		cmd="ls " temp " | head -1";
		cmd | getline tgzName;
		print tgzName;
		close(cmd);

		# 從檔名解析出版本號
		cmd="file=$(ls "temp" | head -1);last=\"${file##*-}\";version=\"${last%.*}\";echo $version;"
		cmd | getline tgzVersion;
		print tgzVersion;
		close(cmd);

		# 解壓縮
		unzipCmd="tar xvzf ./" temp "/" tgzName;
		system(unzipCmd);

		# 修改"./package/package.json"檔
		# 修改「"version": "0.0.0"」
		versionCmd="sed -i \"s/\\\"version.*/\\\"version\\\": \\\"0.0.0\\\"\,/g\" ./package/package.json";
		system(versionCmd);
		# 刪除「"scripts": ...」直到遇到"}"符號，有些package.json格式沒排版會錯誤，改方法
		#scriptsCmd="sed -i \"/\\\"scripts\\\":/,/}/ d; /^$/d\" ./package/package.json";
		#system(scriptsCmd);
		# 刪除有「"prepublish", "prepare", "prepublishOnly", "prepack", "postpack"」字眼的列
		scriptsCmd="sed -i \"/\\\"prepublish\\\": / d; /\\\"prepare\\\": / d; /\\\"prepublishOnly\\\": / d; /\\\"prepack\\\": / d; /\\\"postpack\\\": / d; /^$/d\" ./package/package.json";
		system(scriptsCmd);
		print tgzVersion;

		# publish to privated npm server
		system("sleep 5s");
		system("cd ./package; npm publish --registry http://127.0.0.1:4873;");

		# 修改verdaccio store該package中「0.0.0」改成最新版本號
		reviseCmd="sed -i \"s/\\\"0.0.0\\\"/\\\"" tgzVersion "\\\"/g\" /home/pi/.local/share/verdaccio/storage/"temp"/package.json";
		system(reviseCmd);

		# 解壓縮完休息5秒後，刪除package資料夾
		system("sleep 5s");
		system("rm -r " temp);
		system("rm -r package");		
	}
	else{
		print "====wtf====";
	}
}'

#string="pre-string\\middle\\post-string";
#echo $string;
#string2=`echo $string | perl -pe 's/\\\\middle\\\\/in_the_middle/;'`;

# return 0 to system
exit 0