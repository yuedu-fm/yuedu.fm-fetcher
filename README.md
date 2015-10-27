# yuedu.fm-fetcher

该脚本用于获取yuedu.fm文章信息、频道信息、悦读FM客户端所需的配置信息.

### 使用说明
在使用该脚本之前，请确保已下载七牛同步工具[qrsync](http://developer.qiniu.com/docs/v6/tools/qrsync.html)

在MacOSX命令行执行如下命令
	<pre>
git clone https://github.com/yuedu-fm/yuedu.fm-fetcher
cd yuedu.fm-fetcher
chmod 777 yuedu.fm-fetcher
./yuedu.fm-fetcher</pre>

### 输出
在output目录下会输出悦读FM客户端所需的所有信息，主要包括:
	<pre>
config.jpg
channels.jpg
articles-0.jpg
articles-1.jpg
...
articles-n.jpg</pre>

* config.jpg包含配置信息，包括每个articles文章数目、url、最新文章id等
<pre>
{
"base-url":"http://7xlwed.com1.z0.glb.clouddn.com",
"section":20,
"latest-article-id":966,
"api-channels":"http://7xlwed.com1.z0.glb.clouddn.com/channels",
"api-articles":"http://7xlwed.com1.z0.glb.clouddn.com/articles-",
"api-suffix":".jpg"
}</pre>

* channels.jpg对应yuedu.fm网站的频道信息
<pre>
{
    "list": [
        {
            "id": "1",
            "name": "悦读"
        },
        {
            "id": "2",
            "name": "情感"
        },
        {
            "id": "3",
            "name": "连播"
        },
        {
            "id": "4",
            "name": "校园"
        },
        {
            "id": "5",
            "name": "音乐"
        },
        {
            "id": "6",
            "name": "Labs"
        }
    ]
}</pre>

* articles-x.jpg包含文章信息，文章信息包含如下字段:
<pre>
{
    "id": 1,
    "channel": 1,
    "url": "http://yuedu.fm/article/1/",
    "title": "不相信",
    "author": "龙应台",
    "speaker": "保罗大叔",
    "abstract": "二十岁之前相信的很多东西，后来一件一件变成不相信...",
    "duration": 397,
    "play-count": 6979,
    "picture": "http://yuedu.fm/static/file/large/d9239f8f1141ccb2d5cd9c3cbe3640f2",
    "audio": "http://yuedu.fm/static/file/pod/daa1915c50d3b23439cdcb7d8ae4c231.mp3"
}</pre>

### 版权声明
所获取到的文章信息和频道内容版权归悦读FM（yuedu.fm）所有，请使用者遵循悦读FM（yuedu.fm）版权明细.

