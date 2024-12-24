@echo off
setlocal enabledelayedexpansion
:: 输出注意事项
echo.
echo —————注意事项—————
echo 1.路径中不要有中文。
echo 2.文件名称请勿取中文。
echo.
echo ——开始执行脚本————
echo.
:: 严格检查当前路径是否含中文，修正为检测路径本身含中文
set “cur_path=%cd%”
for /f “tokens=*” %%i in (‘powershell -Command “$ErrorActionPreference = ‘Stop’; try { $result = [bool]([regex]::IsMatch("!cur_path!", "[\u4e00-\u9fff]") -or [regex]::IsMatch((Get-ChildItem -Path "!cur_path!" -Recurse).Name, "[\u4e00-\u9fff]")); Write-Output $result } catch { Write-Error "PowerShell check failed"; exit 1 }”’) do set “has_chinese_char=%%i”
if %has_chinese_char% equ true (
echo 当前路径包含中文，请修正后重试。
pause
exit /b 1
)
echo 当前路径：!cur_path!
echo.
:: 检索配置文件和镜像文件
set “efi_path=”
set “img_path=”
for /f “tokens=*” %%a in (‘dir /b “!cd!”’) do (
if “%%~xa” == “.qcow2” (
set “img_path=%%a”
) else if “%%~xa” == “.fd” (
set “efi_path=%%a”
)
)
if not defined efi_path (
echo 未检索到配置文件，请检查后再试！
echo.
pause
exit /b 1
)
echo 检索到配置文件：!efi_path!
:: 获取镜像名称
:input_img_name
set /p img_name=请输入镜像名称(请输入英文或数字)：
call :validate_input img_name
if not defined img_name (
echo 您输入的不是英文或数字，请重新输入！
echo.
goto :input_img_name
)
:: 获取镜像大小
:input_img_size
set /p img_size=请输入镜像大小/gb：
call :validate_input img_size
if not defined img_size (
echo 您输入的不是数字，请重新输入！
echo.
goto :input_img_size
)
set /a check_size=!img_size!
if!check_size! <= 0 (
echo 输入的文件大小错误，请重新输入！
echo.
goto :input_img_size
)
echo 镜像大小!img_size!/gb.
:: 获取CPU核心数
:input_cpu_cores
set /p cpu_cores=请输入CPU核心数：
call :validate_input cpu_cores
set /a check_cpu_cores=!cpu_cores!
if!check_cpu_cores! <= 0 (
echo 输入的CPU核心数错误，请重新输入！
echo.
goto :input_cpu_cores
)
echo 选择的CPU核心数: %cpu_cores%
:: 获取内存大小
:input_ram_size
set /p ram_size=请输入内存大小/GB：
call :validate_input ram_size
set /a check_ram_size=!ram_size!
if!check_ram_size! <= 0 (
echo 输入的内存大小错误，请重新输入！
echo.
goto :input_ram_size
)
echo 选择的内存大小:!ram_size! GB
echo.
echo 即将创建镜像:!img_name!.qcow2
qemu-img create -f qcow2 “!cd!!img_name!.qcow2”!img_size!g 2>&1 > temp_qemu_img_error.txt
type temp_qemu_img_error.txt | findstr /i “error” >nul
if %errorlevel% equ 0 (
echo 生成镜像文件失败，详细错误:
type temp_qemu_img_error.txt
del temp_qemu_img_error.txt
echo.
pause
exit /b 1
)
if exist “!cd!!img_name!.qcow2” (
echo 生成文件成功：!cd!!img_name!.qcow2
echo.
) else (
echo 生成镜像文件失败，请检查后再试！
echo.
pause
exit /b 1
)
echo.
echo ——是否开始启动安装———
echo ——1.启动安装———––
echo ———2.结束脚本————
echo.
:: 用户选择是否安装
:input_select_go
set /p select_num=请输入你的选择：
if “!select_num!” == “1” (
echo 启动安装！
echo.
) else if “!select_num!” == “2” (
echo 结束脚本！
echo.
pause
exit /b 0
) else (
echo 选择错误，请重新输入！
echo.
goto :input_select_go
)
:: 选择ISO文件，优化文件选择方式
:input_isopath_go
set “isopath=”
for /f “tokens=* delims=” %%f in (‘dir /b /a-d *.iso’) do (
echo %%~ff
set /p choice=这是一个ISO文件，是否选择(Y/N)?
if /i “!choice!”==“y” (
set “isopath=%%f”
goto :break_isopath
)
)
:break_isopath
if not defined isopath (
echo 选择文件错误，请重新选择！
echo.
goto :input_isopath_go
)
echo 选择镜像:!isopath!
echo.
echo —执行安装程序中，请勿关闭—
qemu-system-x86_64.exe -m “!ram_size!g” -cpu host -smp “!cpu_cores!” -bios “!efi_path!” -device vga -device nec-usb-xhci -device usb-mouse -device usb-kbd -drive “if=none,file="!cd!!img_name!.qcow2",id=hd0” -device virtio-blk-device,drive=hd0 -drive “if=none,file="!isopath",id=cdrom,media=cdrom” -device virtio-scsi-device -device scsi-cd,drive=cdrom -net user,hostfwd=tcp::2222-:22 -net nic 2>&1 > temp_qemu_system_error.txt
type temp_qemu_system_error.txt | findstr /i “error” >nul
if %errorlevel% equ 0 (
echo Qemu启动失败，详细错误:
type temp_qemu_system_error.txt
del temp_qemu_system_error.txt
echo.
)
echo ––结束安装，下一次启动请执行start.bat—––
pause
:: 校验输入是否为数字
:validate_input
set “input=!%~1!”
echo %input%|findstr /r “^[0-9]*$” >nul
if %errorlevel% equ 1 (
set %~1=
)
goto :eof
