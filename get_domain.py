import ipaddress
import os
import re
import tqdm
from requests import get
from tld import get_tld
from tld.utils import update_tld_names

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
find_domains('./tachiyomi-extensions/src/zh')
find_domains('./tachiyomi-extensions/src/all')

# 用第三方库检测域名是否合法
# 更新顶级域名列表
update_tld_names()

# 去重
domain_list = list(set(domain_list))

# 排除特定域名
with open('exclude.txt', 'r') as f:
    exclude = [line.strip() for line in f]
for domain in domain_list:
    for exclude_s in exclude:
        if exclude_s in domain:
            try:
                domain_list.remove(domain)
            except:
                pass

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

temp_domain = []

# 读取文件中的所有IP CIDR
with open('cn.txt', 'r') as f:
    networks = [ipaddress.ip_network(line.strip()) for line in f]

is_cn = 0

for domain in tqdm.tqdm(domain_list):
    headers = {'Accept': 'application/dns-json'}
    params = {'name': domain, 'type': 'A', 'edns_client_subnet': '122.119.122.0/24'}
    try:
        resp = get('https://223.5.5.5/resolve', headers=headers, params=params).json()
    except:
        continue

    # 判断Answer是否为空
    if 'Answer' not in resp.keys():
        continue

    answers = resp['Answer']
    for answer in answers:
        # 判断是否为IP地址
        if answer['type'] == 1:
            ip = answer['data']
            # 判断是否为国内IP
            if ipaddress.ip_address(ip) in networks:
                is_cn = 1
    if is_cn == 1:
        is_cn = 0
        break
    else:
        temp_domain.append(domain)

domain_list = temp_domain

# 保存结果
with open('manga', 'w', encoding='utf-8') as f:
    for domain in domain_list:
        f.write(domain + '\n')
