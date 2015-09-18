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

set -e

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

USAGE: $0 

DESCRIPTION:

EOF
}

base_url="http://yuedu.fm"

# 获取文章信息
# input article_id
fetch_article() {
    url="$base_url/article/$1/"

    curl $url > tmp.html

    exit


    html=`curl $url`

    audio_url=`echo $html|sed -n '/mp3:s"/,/"/p'`
    echo $audio_url
}

fetch_article 900

