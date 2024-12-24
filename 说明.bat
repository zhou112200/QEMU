@echo off
setlocal enabledelayedexpansion

:: 输出提示信息
echo.
echo -----------------脚本运行提示-----------------
echo 该脚本将执行以下操作：
echo 1. 检查当前路径是否包含中文字符。
echo 2. 检索当前目录下的配置文件和镜像文件。
echo 3. 获取用户输入的镜像名称、大小、CPU核心数和内存大小。
echo 4. 创建新的qcow2格式镜像文件。
echo 5. 选择ISO文件并启动虚拟机安装过程。
echo.
echo 注意事项：
echo - 路径中不要有中文。
echo - 文件名称请勿取中文。
echo.
echo 请仔细阅读以上提示信息，确保您了解脚本的功能和注意事项。
echo.
echo 按任意键继续运行脚本，或按Ctrl+C退出...
pause >nul

:: 运行脚本
call QEMU.bat