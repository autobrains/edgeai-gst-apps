#!/bin/bash

#  Copyright (C) 2021 Texas Instruments Incorporated - http://www.ti.com/
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#    Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the
#    distribution.
#
#    Neither the name of Texas Instruments Incorporated nor the names of
#    its contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

GREEN='\033[0;32m'
NOCOLOR='\033[0m'


setup_imx728(){

    gpioset gpiochip2 7=0
    gpioset gpiochip2 10=0
    gpioset gpiochip1 90=0

    sleep 1

    gpioset gpiochip2 7=1
    gpioset gpiochip2 10=1
    gpioset gpiochip1 89=0
    sleep 0.01

    gpioset gpiochip1 90=1

    sleep 1

    IMX728_CAM_FMT='[fmt:SRGGB12_1X12/3856x2176]'

    insmod /opt/edgeai-gst-apps/imx728.ko

    sleep 1
    echo 0 > /sys/module/imx728/parameters/use_sf811_config

    count=0
    for media_id in {0..1}; do
    for name in `media-ctl -d $media_id -p | grep entity | grep imx728 | cut -d ' ' -f 5`; do
        CAM_SUBDEV=`media-ctl -d $media_id -p -e "imx728 $name" | grep v4l-subdev | awk '{print $4}'`
        media-ctl -v -d $media_id --set-v4l2 ''"\"imx728 $name\""':0 '$IMX728_CAM_FMT''

        CSI_BRIDGE_NAME=`media-ctl -d $media_id -p -e "imx728 $name" | grep csi-bridge | cut -d "\"" -f 2`
        CSI2RX_NAME=`media-ctl -d $media_id -p -e "$CSI_BRIDGE_NAME" | grep "ticsi2rx\"" | cut -d "\"" -f 2`
        CSI2RX_CONTEXT_NAME="$CSI2RX_NAME context 0"

        CAM_DEV=`media-ctl -d $media_id -p -e "$CSI2RX_CONTEXT_NAME" | grep video | awk '{print $4}'`
        CAM_DEV_NAME=/dev/video-rpi-cam$count

        CAM_SUBDEV_NAME=/dev/v4l-rpi-subdev$count

        ln -snf $CAM_DEV $CAM_DEV_NAME
        ln -snf $CAM_SUBDEV $CAM_SUBDEV_NAME

        echo -e "${GREEN}CSI Camera $media_id detected${NOCOLOR}"
        echo "    device = $CAM_DEV_NAME"
        echo "    name = imx728"
        echo "    format = $IMX728_CAM_FMT"
        echo "    subdev_id = $CAM_SUBDEV_NAME"
        echo "    isp_required = yes"
        count=$(($count + 1))
    done
    done
}


setup_imx728
