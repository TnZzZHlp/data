from math import e
import os
import re
from tqdm import tqdm
domain_list = []

def find_domains(path):
    domain_pattern = re.compile(r'[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+\.?')

    # 定义要排除的文件类型
    excluded_filetypes = ['.jpg', '.png', '.gif', '.bmp', '.jpeg', '.ico', '.tiff', '.tif', '.raw']

    for root, _, files in os.walk(path):
        for file in files:
            # 排除非文本文件
            if os.path.splitext(file)[1] in excluded_filetypes:
                continue

            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'rb') as f:
                    content = f.read().decode('utf-8', errors='ignore')
                    matches = domain_pattern.finditer(content)
                    for match in matches:
                        domain_list.append(match.group())
            except:
                print(f'无法读取文件: {file_path}')

# 判断上次文件是否存在,存在则删除
if os.path.exists('manga'):
    os.remove('manga')
else:
    pass
# 调用函数
find_domains('./src')

# 用第三方库检测域名是否合法
from tld import get_tld
from tld.utils import update_tld_names

# 更新顶级域名列表
update_tld_names()

# 去重
domain_list = list(set(domain_list))

upperRegex = re.compile(r'[A-Z]')
# 检测域名是否合法，不合法则删除
valid_domains = []
for domain in domain_list:
    try:
        # 若域名中存在大写字母，则删除
        if upperRegex.search(domain) is None:
            get_tld(domain, fix_protocol=True)
            valid_domains.append(domain)
    except:
        pass

domain_list = valid_domains



# 排除特定域名
exclude = ['qq.com', 'android.com', 'www.w3xue.com', 'www.w3cschool.cn', 'iqiyi.com', 'hycdn.cn']
for domain in domain_list:
    for exclude_s in exclude:
        if exclude_s in domain:
            domain_list.remove(domain)

# 解析域名，如果没有解析到IP地址，则删除
import socket

valid_domains = []
for domain in domain_list:
    try:
        ip = socket.gethostbyname(domain)
        valid_domains.append(domain)
    except:
        pass

domain_list = valid_domains

# 保存结果
with open('manga', 'w', encoding='utf-8') as f:
    for domain in domain_list:
        f.write(domain + '\n')