# R329-Tina-jishu

临时的文档，之后会同步在 maixpy3 的文档里。

https://www.cnblogs.com/juwan/p/14650733.html

https://r329.docs.allwinnertech.com/

## SDK docker 

docker pull tdleiyao/ubuntu-sipeed_r329_env:bionic

docker run --name=Ubuntu_R329_TD -v /宿主机仓库路径:/容器内仓库路径 -ti tdleiyao/ubuntu-sipeed_r329_env:bionic bash

## ZouYi

使用矽速科技提供的docker环境进行开发：
> 注：请保证至少有20GB的空闲磁盘空间
```
# 方法一，从docker hub下载，需要梯子
sudo docker pull zepan/zhouyi
# 方法二，百度云下载镜像文件（压缩包约2.9GB，解压后约5.3GB）
# 链接：https://pan.baidu.com/s/1yaKBPDxR_oakdTnqgyn5fg 
# 提取码：f8dr 
gunzip zhouyi_docker.tar.gz
sudo docker load --input zhouyi_docker.tar
```
下载好docker后即可运行其中的例程测试环境是否正常：
```
sudo docker run -i -t zepan/zhouyi  /bin/bash

cd ~/demos/tflite
./run_sim.sh
python3 quant_predict.py
```
