[English](#en) | [中文](#cn)

　

<span id="en">Install FTD3XX Driver and Python ftd3xx Library</span>
====================================

To run FT600 related Python programs on Windows, follow these steps:

> Note: This document was written in 2019. If the official website is updated later, the general process will definitely remain unchanged, but some operational details (for example, the download file cannot be found on the official website) will need to be worked around.

### Step1: Install FTD3XX Driver and download FTD3XX.dll

Go to [D3XX Driver webpage](https://www.ftdichip.com/Drivers/D3XX.htm) , in the table in the D3XX Drivers column, download the  driver (.exe file) and install it. As shown below.

Also, to download the DLL, unzip it and find the FTD3XX.dll file that matches your computer. For a 32-bit computer, find the 32-bit(i386) DLL; for a 64-bit computer, find the 64-bit(amd64) DLL. If the file name is FTD3XX64.DLL, etc., please always rename it to FTD3XX.DLL

![FT600驱动下载](./figures/ft600_driver_download.png)



### Step2: Verify Installation

Insert the FT600 USB port of the development board into the computer. If the driver is installed successfully, a **FTDI FT600 USB 3.0 Bridge Device** should be identified in the Windows Device Manager. As shown below.

![FT600被识别](./figures/ft600_ready.png)

### Step3: Install Python3

If you don't have Python3 installed, please go to [Anaconda official website](https://www.anaconda.com/products/individual) to download and install Python3, the major version number must be Python3, not Python2.

Note: If it is a 32-bit computer, please install 32-bit Python; if it is a 64-bit computer, please install 64-bit Python.

### Step4: Install ftd3xx Library for Python

Open CMD or PowerShell, run command:

```powershell
python -m pip install ftd3xx
```

~~ftd3xx library doesn't seem to be able to be installed with the pip install command. Please open the http://www.ftdichip.cn/Support/SoftwareExamples/FT60X.htm webpage, there is Python support at the bottom.Download and unzip it, find **setup.py** in it, and run the CMD command pytho n setup.py install to install it.~~ 

### Step5: Copy FTD3XX.dll File to Python Environment

Copy the FTD2XX.DLL file we downloaded in step1 to the Python's root directory (for example, on my computer, the Python root directory is **C:/Anaconda3/** ). Note that 32-bit Python must correspond to a 32-bit DLL; 64-bit Python must correspond to a 64-bit DLL.

Then, you can run the following statement in python to verify its installation:

```python
import ftd3xx
```

Now the Python runtime environment required by the FT600 is ready.

　

　

　

　

<span id="cn">安装 FTD3XX 驱动和 Python FTD3XX 库</span>
====================================

要在 Windows 上运行 FT600 相关的 Python 程序，请进行以下步骤： 

> 注：该文档写于 2019 年，如果之后官网更新，大致流程肯定不变，但一些操作细节（例如官网上找不到下载文件了）就要变通变通了。

### 步骤1：准备 D3XX 驱动 和 FTD3XX.DLL

进入 [D3XX Driver 官网页面](https://www.ftdichip.com/Drivers/D3XX.htm) ，在 D3XX Drivers 那一栏的表格里。下载exe形式的驱动并安装。如下图。

另外，要下载 DLL 压缩包， 解压后在里面找到符合你计算机的 FTD3XX.DLL 文件。若为32位计算机，请找到 32-bit(i386) DLL；若为64位计算机，请找到 64-bit (amd64) DLL。如果文件名是 FTD3XX64.DLL 等，请一律重命名为 FTD3XX.DLL

![FT600驱动下载](./figures/ft600_driver_download.png)

　

### 步骤2：验证驱动安装

将开发板的 FT600 USB 口插入电脑，如果驱动安装成功，则 Windows 设备管理器里应该识别出 **FTDI FT600 USB 3.0 Bridge Device** 。

![FT600被识别](./figures/ft600_ready.png)

### 步骤3：安装 python3

如果你没有安装 Python3， 请前往 [Anaconda官网](https://www.anaconda.com/products/individual) 下载安装 Python3 ，必须是 Python3 ，而不是 Python2。

注：若为32位计算机，请安装32位的Python；若为64位计算机，请安装64位的Python。

### 步骤4：安装 Python ftd3xx 库

打开 CMD 或 Powershell ，运行：

```
python -m pip install ftd3xx
```

~~ftd3xx似乎无法用pip install命令来安装。请打开http://www.ftdichip.cn/Support/SoftwareExamples/FT60X.htm网页， 网页最下方有 Python 的支持。下载后解压，在里面找到setup.py，在本目录中运行 CMD 命令python setup.py install来安装。~~

### 步骤5：复制 FTD3XX.DLL 文件到 Python 环境中

复制步骤1中我们找到的 FTD3XX.DLL 文件到 Python 根目录（例如在我的电脑上， Python 根目录是 **C:/Anaconda3/** ）。注意32位的Python必须对应32位的DLL；64位的Python必须对应64位的DLL。

然后，可以在 python 中运行以下语句来验证安装：

```python
import ftd3xx
```

至此，FT600 所需的 Python 运行环境已就绪。
