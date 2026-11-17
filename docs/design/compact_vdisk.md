## TODO: Compact vdisk feat

写一个 compact_vdisk 的 PowerShell 脚本

步骤一: 查找 DISK 位置
* `Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\*" | Select-Object DistributionName, BasePath | Format-Table -AutoSize`

WSL 默认的文件名称是 file.vhdx,需要考虑被重命名的校验

步骤二: 压缩
* 停掉 WSL `wsl --shutdown`
* 启动工具 `diskpart`
* 选择 DISK `select vdisk file="path/to/file.vhdx"`
* 开始压缩 `compact vdisk`

静默后台,不要弹窗,需要显示压缩进度
