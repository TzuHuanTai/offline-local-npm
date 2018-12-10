# offline-local-npm

For some people or companies who wanna copy the hole npm service into LAN

node.js版本請用10.X.X以上的！原本用8.X的有時跑到一半會卡住！

## 1.安裝verdaccio ##
先在連網環境安裝好verdaccio


> sudo npm install -g verdaccio




## 2. 啟用verdaccio ##
安裝完的verdaccio資料路徑：

`/usr/lib/node_modules/verdaccio`

verdaccio storage路徑：

`/home/{user}/.local/share/verdaccio/storage`

verdaccio config路徑：

`/home/{user}/.config/verdaccio/config.yaml`

可以不用sudo執行，先直接用一般使用者

可以由CLI執行「verdaccio」或 直接對檔案執行

> /usr/lib/node_modules/verdaccio/bin/verdaccio





## 3. 註冊adduser ##
> npm adduser --registry http://127.0.0.1:4873

如果自己用不想註冊權限控管，就把「config.yaml」裡packages的「publish」權限改成「$all」



## 4. 透過Nginx proxy代理 ##
設定nginx的proxy

> nano /usr/local/nginx/conf/nginx.confog

將連來server 80 port的請求都導向本機的4873 port

切記，header一定要設定！

    server {
	    listen 80;	     
	    server_name localhost;
	     
	    location / {
		    proxy_pass http://127.0.0.1:4873;
		    proxy_set_header Upgrade $http_upgrade;
		    proxy_set_header Connection 'upgrade';
		    proxy_set_header Host $host;
	    }
    }


## 5. 下載Package的套件 ##
以leaflet為例
> npmDownload -p leaflet -a -o ./

載完後解壓縮

> tar xvzf leaflet-1.3.4.tgz



## 6. 發佈開源套件到verdaccio ##
進入解壓縮的資料夾找到package.json檔。

> cd ./package

因為verdaccio會判斷開源套件的版本資訊，若有重複就error跳出。經過觀察，開源軟體初始版本號不是從「0.1.0」就是「1.0.0」開始，所以把json檔中的「"version"」改成「"0.0.0"」繞過他的判斷。

預設npm service改為本機

> npm set registry http://127.0.0.1:4873

再到`/home/{user}/package`底下，將解壓縮的開源套件發佈到自己的privated npm server。

> npm publish --registry http://127.0.0.1:4873

verdaccio會將套件重新壓縮成.tgz放入套件名稱的資料夾`/home/{user}/.local/share/verdaccio/storage/{packageName}`

同時資料庫`/home/{user}/.local/share/verdaccio/storage/.sinopia-db.json`也會寫入套件名稱。

這邊重點是在我們publish的同時，要讓verdaccio上去https://registry.npmjs.org抓此開源套件版本歷史的json格式詳細資料！



## 7. 修正最新版本號 ##
`/home/{user}/.local/share/verdaccio/storage/{packageName}/package.json`中，json格式詳細資料也會記載這次publish的版本號「0.0.0」同時變為最新版本，所以
> npm install {package}

要是沒指定版本就自動抓「0.0.0」版！

我的懶人做法是把檔案中收尋到的「"0.0.0"」全部取代為「這次package的版本號」，這樣會讓最新版本有兩個同樣的資料衝突！

聰明的verdaccio解讀package.json時，會自動把衝突資料舊的部分移從package.json中移除掉！太棒了！

verdaccio要讓package可以運作此套件必須在「.sinopia-db.json」清單中、有「json格式詳細資料」。

如果滿足以上兩個條件，從其他server直接複製貼上過來也可以



## 8. 把流程1~7寫成shell script大量匯入 ##
先到 [all-the-package-names](https://github.com/nice-registry/all-the-package-names) 下載names.json，這是人家整理好npm上所有packages的名稱json檔。

然後寫個bash script ，大概流程如下：

- 利用「cat ./names.json」搭配「awk」一列一列的讀取names.json裡面的套件名稱

- 搭配npmDownload下載package

- 重新命名下載好的package folder路徑，因為npmDownload下載的路徑符號是按照Windows的反斜線「\」，Linux路徑只能辨識「/」

- 隨便抓一個壓縮檔，解壓縮後用「sed」指令修改`./package/package.json`檔案的版本號

- `./package/package.json`裡面的"script"若有"prepublishOnly"、"prepublish"、"prepare"、"prepack"、"postpack"的話會影響到npm publish，用「sed」把他們清掉。(反正最後進去verdaccio的壓縮檔才是真的，這邊都只是為了向npm server自動索取package詳細資料的json檔)
*原本想把整個"scripts"清掉，有時會遇到排版問題出錯！*

- 將此package publish到verdaccio上後，更改`/home/{user}/.local/share/verdaccio/storage/{packageName}/package.json`中所有版本號為「0.0.0」=>「這次下載的版本」

- 將下載套件所有版本的{.tgz}壓縮檔移動到verdaccio的存放路徑，`/home/{user}/.local/share/verdaccio/storage/{packageName}`

- 刪除路徑底下本次下載的套件與解壓縮的東西，不然幾十萬套載下來硬碟會炸掉。

- 把成功的到紀錄log檔中，然後再迴圈跑一次流程



## 常用指令 ##
找出linux下global node_modules擺放位置

> npm root -g

移除package

> npm unpublish --force {packageName}

查看port被占用的情況

> sudo netstat -apn | grep 80

殺掉占用程序

> kill {pid_number}



## 參考資料 ##
1. [[問題] 在 shell/shell script 下做斜線取代](https://www.ptt.cc/bbs/Perl/M.1308547412.A.39A.html)

1. [Assigning system command's output to variable](https://stackoverflow.com/questions/1960895/assigning-system-commands-output-to-variable)

1. [Advanced Chapter 3 : sed 和 awk](http://wanggen.myweb.hinet.net/ach3/ach3.html?MywebPageId=201851543969247374)

1. [npm-scripts](https://docs.npmjs.com/misc/scripts)

1. [How to delete a Json object from Json File by sed command in BASH](https://stackoverflow.com/questions/38028600/how-to-delete-a-json-object-from-json-file-by-sed-command-in-bash)

1. [cut string on last delimiter](https://unix.stackexchange.com/questions/217628/cut-string-on-last-delimiter)

1. [Extract filename and extension in Bash](https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash)
