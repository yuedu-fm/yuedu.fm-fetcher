#!/bin/bash
#
# Copyright (C) 2014 Wenva <lvyexuwenfa100@126.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is furnished
# to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


spushd() {
     pushd "$1" 2>&1> /dev/null
}

spopd() {
     popd 2>&1> /dev/null
}

info() {
     local green="\033[1;32m"
     local normal="\033[0m"
     echo -e "[${green}INFO${normal}] $1"
}

error() {
     local red="\033[1;31m"
     local normal="\033[0m"
     echo -e "[${red}ERROR${normal}] $1"
}

# 获取当前目录
current_dir() {
    if [ ${0:0:1} = '/' ] || [ ${0:0:1} = '~' ]; then
        echo "$(dirname $0)"
    else
        echo "`pwd`/$(dirname $0)"
    fi
}

usage() {
cat << EOF

USAGE: $0 [<qrsync command path>]

DESCRIPTION:
<qrsync command path> qrsync command's path(must be set if under cron)

EXAMPLE:
$0 /usr/local/bin/qrsync

EOF
}

base_url="http://yuedu.fm"

json_header() {
    echo "{" > $1
}

json_footer() {
    echo "}" >> $1
}

json_array_header() {
    echo "[" >> $1
}

json_array_footer() {
    echo "]" >> $1
}

trim() {
    echo `echo "$1" | awk 'gsub(/^ *| *$/,"")'` 
}

# separator expression file
awk_trim() {
    result=`awk -F"$1" "$2" $3`
    echo `trim "$result"`
}

# 转换12:12:12到秒
time_string_to_seconds() {
    echo `echo $1|awk -F: '{if(NF>=3){print $1*60*60+$2*60+$3}else if(NF==2){print $1*60+$2}else if(NF==1){print $1}else{print 0};}'`
}

# 获取最新文章id
fetch_latest_article_id() {
    local article_id=0
    for channel in {1..6}
    do
        id=`curl http://yuedu.fm/channel/$channel/|sed -n '/div class="channel-pic fl"/,/div>/p'|awk '/a href/{print $0}'|sed -n '1p'|awk -F\/ '{print $3}'`
        if [ "$id" -gt "$article_id" ];then
            article_id=$id
        fi
    done
   echo $article_id
}

# 获取文章信息
# @param article_id
fetch_article() {
    local url="$base_url/article/$1/"
    local tmp_file="tmp.html"
    local json="{\"id\":$1,"

    curl $url > $tmp_file

    channel=`sed -n '/div class="channel-item"/,/channel-list/p' $tmp_file|awk -F\/ '/channel\//{print $3}'`
    if [ "$channel" == "" ];then
        echo ""
        return
    fi
    json="$json\"channel\":$channel,"

    json="$json\"url\":\"$url\","

    title=`awk_trim '[\<\>]' '/div class="item-name"/{print $3}' $tmp_file` 
    json="$json\"title\":\"$title\","
    author=`awk_trim '[\<\>]'  '/class="fa fa-pencil"/{print $7}' $tmp_file`
    json="$json\"author\":\"$author\","
    speaker=`awk_trim '[\<\>]'  '/class="fa fa-microphone"/{print $7}' $tmp_file`
    json="$json\"speaker\":\"$speaker\","
    abstract=`awk_trim \" '/meta name="description"/{print $4}' $tmp_file`
    json="$json\"abstract\":\"$abstract\","
    duration=`awk_trim '[\<\>]'  '/class="fa fa-clock-o"/{print $7}' $tmp_file`
    duration=`time_string_to_seconds "$duration"`
    json="$json\"duration\":$duration,"
    count=`awk_trim '[\<\>]'  '/class="fr">播放/{print $5}' $tmp_file`
    if [ -z "$count" ];then
        count=0
    fi
    json="$json\"play-count\":$count,"

    picture=`sed -n '/div class="item-pic">/,/>/p' $tmp_file|awk_trim "[=\"]" '/img/{print $3}'`
    picture=`trim "$picture"`
    json="$json\"picture\":\"$picture\","

    audio=$base_url`awk_trim \"  '/mp3:/{print $2}' $tmp_file`
    json="$json\"audio\":\"$audio\""

    rm -rf $tmp_file
    echo "$json}"
}

# 获取指定范围内文章
# @param begin_id
# @param end_id
# @param json_file
fetch_articles() {
    local begin_id=$1
    local end_id=$2
    local json_file=$3
    local article=""

    json_header $json_file

    echo "\"list\":" >> $json_file
    json_array_header $json_file

    local i
    for((i=$begin_id;i<=$end_id;i++))
    do
        if [ "$article" != "" ];then
            echo "," >> $json_file
        fi

        info "Fetching article $i ..."
        article=`fetch_article $i`
        echo $article >> $json_file
    done
    json_array_footer $json_file

    if [ "$begin_id" != "0" ];then
        ((begin_id--))
    fi
    echo ",\"next\":$begin_id" >> $json_file

    json_footer $json_file
}

# 获取所有文章
# @param latest_article_id
# @param section
# @param json_file
# @param suffix
fetch_all_articles() {
    local latest_id=$1
    local section=$2
    local json_file=$3
    local suffix=$4

    max_section=`expr $latest_id / $section`
    local i
    for((i=0;i<=$max_section;i++)) 
    do
        begin_id=`expr $i \* $section`

        if [ "$i" == "$max_section" ];then
            end_id=$latest_id
        else
            end_id=`expr $begin_id + $section - 1`
        fi

        # 只更新最新section及未下载的section
        local file="$json_file$i$suffix"
        if [[ "$i" == "$max_section" || ! -f "$file" ]];then
            fetch_articles $begin_id $end_id $file
        fi
    done

    
}

# 获取频道信息
# @param json_file
# @param suffix
fetch_channels() {
    local json_file="$1$2"
    local url=$base_url
    local tmp_file="tmp.html"

    json_header $json_file

    echo "\"list\":" >> $json_file
    json_array_header $json_file

    # 获取所有频道  格式: 1 悦读 2 情感 3 连播 4 校园 5 音乐 6 Labs
    `curl $url > $tmp_file`
    items=`sed -n '/div class="menu"/,/div>/p' $tmp_file|awk -F "[\/\<\>]" '/channel/{print $4,$6}'`

    local index=1
    local json=""
    for item in $items
    do
        if test `expr $index % 2` != 0;then 
            if [ "$json" != "" ]; then 
                json="$json,"
            fi
            json="$json{\"id\":\"$item\","
        else 
            json="$json\"name\":\"$item\"}"
        fi
        (( index++ ))
    done

    rm $tmp_file

    echo $json >> $json_file

    json_array_footer $json_file
    json_footer $json_file
}

# 配置
# @param json_file
fetch_config() {
    local json_file=$1
    json_header $json_file

    echo "\"base-url\":\"$qndomain\"," >> $json_file
    echo "\"section\":$section," >> $json_file
    echo "\"latest-article-id\":$latest_article_id," >> $json_file
    echo "\"api-channels\":\"$qndomain/$channels_json\"," >> $json_file
    echo "\"api-articles\":\"$qndomain/$articles_json\"," >> $json_file
    echo "\"api-suffix\":\"$suffix\"," >> $json_file
    # 由于苹果审核要求需要授权才可以下载，因此在新版本升级时必须关闭下载功能，以保证审核通过
    echo "\"allow-download\":0" >> $json_file

    json_footer $json_file
}

# Check qrsync
if [ "$#" -ge 1 ];then
    qrsync=$1
fi

if [ "$qrsync" == "" ];then
    command -v qrsync >/dev/null 2>&1 || { error >&2 "The qrsync is not installed. Please goto qiniu website(http://developer.qiniu.com/docs/v6/tools/qrsync.html) to get it."; exit -1; }
    qrsync=qrsync
else
    if [ ! -f "$qrsync" ];then
        error "File $qrsync does not exist."
        exit -1
    fi
fi

spushd `current_dir`

mkdir -p output

spushd output

# 配置信息
section=20

# 由于七牛服务器只运行上传媒体文件，因此伪装成.jpg
suffix=".jpg"
config_json="config$suffix"
articles_json="articles-"
channels_json="channels"
qndomain="http://7xlwed.com1.z0.glb.clouddn.com"
touch $config_json

info "正在检查是否有新文章..."
old_latest_article_id=`awk -F "[:,]" '/latest-article-id/{print $2}' $config_json`
if [ "$old_latest_article_id" == "" ];then
    old_latest_article_id=0
fi
latest_article_id=`fetch_latest_article_id`

if [ "$old_latest_article_id" -ge "$latest_article_id" ];then
    info '暂时没有新文章，已退出.'
    exit 0
fi

info "获取新文章信息..."
fetch_channels $channels_json $suffix
fetch_all_articles $latest_article_id $section $articles_json $suffix
fetch_config $config_json 

spopd

info "同步到云端..."

`"$qrsync" yuedu.fm-syn.conf`

info "同步完成."
spopd

