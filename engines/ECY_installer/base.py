from ECY_installer import pypi_tools
from urllib.request import urlretrieve

from termcolor import colored
from tqdm import tqdm
from colorama import init

init()


class DownloadProgressBar(tqdm):
    def update_to(self, b=1, bsize=1, tsize=None):
        if tsize is not None:
            self.total = tsize
        self.update(b * bsize - self.n)


def DownloadFileWithProcessBar(url: str, output_path: str):
    with DownloadProgressBar(unit='B',
                             unit_scale=True,
                             miniters=1,
                             desc=url.split('/')[-1]) as t:
        import ssl
        from urllib.request import urlopen
        from urllib.request import Request
        
        # 创建 SSL 上下文
        context = ssl._create_unverified_context()
        
        # 打开URL并下载
        req = Request(url)
        with urlopen(req, context=context) as response:
            total_size = int(response.headers.get('content-length', 0))
            block_size = 1024
            t.total = total_size
            
            with open(output_path, 'wb') as f:
                while True:
                    block = response.read(block_size)
                    if not block:
                        break
                    f.write(block)
                    t.update(len(block))
        t.close()
        # urlretrieve(url, filename=output_path, reporthook=t.update_to)


def PrintGreen(msg, colored_msg):
    print(msg, colored(colored_msg, 'white', 'on_green'))


def PrintPink(msg, colored_msg):
    print(msg, colored(colored_msg, 'white', 'on_magenta'))


def DownloadFile(url: str, output_path: str) -> None:
    print(url)
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(output_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                # If you have chunk encoded response uncomment if
                # and set chunk_size parameter to None.
                # if chunk:
                f.write(chunk)
            f.close()


class Install(object):
    def __init__(self, name: str):
        self.name: str = name

    def DownloadFile(self, url: str, output_path: str):
        DownloadFile(url, output_path)

    def DownloadFileWithProcessBar(self, url: str, output_path: str):
        DownloadFileWithProcessBar(url, output_path)

    def InstallEXE(self, server_name: str, platform: str,
                   save_dir: str) -> dict:
        installed_dir = pypi_tools.Install(
            'ECY-%s-%s' % (platform, server_name), save_dir)
        res = installed_dir + \
            '/ECY_exe/ECY_%s_%s.exe' % (server_name, platform),
        return {'cmd': res, 'installed_dir': installed_dir}

    def CleanWindows(self, context: dict) -> dict:
        return {}

    def CleanLinux(self, content: dict) -> dict:
        return {}

    def CleanmacOS(self, content: dict) -> dict:
        return {}

    def Windows(self, context: dict) -> dict:
        return self.InstallEXE(self.name, 'Windows', context['save_dir'])

    def Linux(self, context: dict) -> dict:
        return self.InstallEXE(self.name, 'Linux', context['save_dir'])

    def macOS(self, context: dict) -> dict:
        return self.InstallEXE(self.name, 'macOS', context['save_dir'])

    def CheckmacOS(self, context: dict) -> dict:
        return {}

    def CheckWindows(self, context: dict) -> dict:
        return {}

    def CheckLinux(self, context: dict) -> dict:
        return {}

    def Readme(self, context: dict) -> str:
        return ""
