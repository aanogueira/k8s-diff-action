import re
import sys
import os
import base64
import subprocess
import yaml
import json
import logging

# create logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)

# create formatter
formatter = logging.Formatter(
    '%(asctime)s - %(levelname)s - %(message)s')

# add formatter to ch
ch.setFormatter(formatter)

# add ch to logger
logger.addHandler(ch)


def parse_yaml_file(yaml_file):
    with open(yaml_file, 'r') as stream:
        try:
            data = yaml.safe_load(stream)
            name = data.get('metadata', {}).get('name')
            namespace = data.get('metadata', {}).get('namespace')
            chart_version = data.get('spec', {}).get(
                'chart', {}).get('spec', {}).get('version', '*')
            chart_name = data.get('spec', {}).get(
                'chart', {}).get('spec', {}).get('chart')
            chart_repo = data.get('spec', {}).get('chart', {}).get(
                'spec', {}).get('sourceRef', {}).get('name')
            dic_values = data.get('spec', {}).get('values', {})
            yaml_values = yaml.dump(dic_values)
            dic_values_from = data.get('spec', {}).get('valuesFrom', {})
            yaml_values_from = yaml.dump(dic_values_from)
            if name and namespace and chart_repo and chart_name:
                return (name, namespace, chart_repo, chart_version, chart_name, yaml_values, yaml_values_from)
            else:
                return None
        except yaml.YAMLError as exc:
            logging.error(f"Error in parsing YAML file: {exc}")
            return None


def extract_fields(file_path):
    with open(file_path, 'r') as file:
        yaml_data = yaml.safe_load(file)
        name = yaml_data.get('metadata', {}).get('name', '')
        url = yaml_data.get('spec', {}).get('url', '')
        secret_ref_name = yaml_data.get('spec', {}).get(
            'secretRef', {}).get('name', '')
        return name, {'url': url, 'secret': secret_ref_name}


def process_folder(folder_path):
    results = {}
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isfile(file_path) and file_path.endswith('.yaml'):
            key, fields = extract_fields(file_path)
            results[key] = fields
    return results


def add_helm_repo(chart_repo, chart_url, secret=None):
    helm_command = ['helm', 'repo', 'add', chart_repo, chart_url, '--force-update']
    if secret:
        secret_command = ['kubectl', 'get', 'secret', '-n',
                          'flux-system', secret, '-o', 'jsonpath={.data}']
        secret_result = subprocess.run(secret_command, capture_output=True)
        if secret_result.returncode == 0:
            username = base64.b64decode(json.loads(secret_result.stdout)[
                                        'username']).decode('utf-8')
            password = base64.b64decode(json.loads(secret_result.stdout)[
                                        'password']).decode('utf-8')
            helm_command_creds = ['--username',
                                  username, '--password', password]
            helm_result = subprocess.run(
                helm_command + helm_command_creds, capture_output=True)
            if helm_result.returncode != 0:
                logger.error(helm_result.stderr.decode("utf-8"))
        else:
            logger.error(secret_result.stderr.decode("utf-8"))
    else:
        helm_result = subprocess.run(helm_command, capture_output=True)
        if helm_result.returncode != 0:
            logger.error(helm_result.stderr.decode("utf-8"))


def get_helm_diff(name, chart_repo, chart_name, chart_version, namespace, values, values_from):
    cm_values_from = ""
    yaml_values_from = yaml.safe_load(values_from)
    for cm in yaml_values_from:
        cm_name = cm["name"]
        cm_key =f'.data.{re.escape(cm["valuesKey"])}'
        cm_values_command = f"kubectl get cm {cm_name} -n {namespace} -o 'jsonpath={{{cm_key}}}'"
        cm_values = subprocess.Popen(
            cm_values_command, stdout=subprocess.PIPE, shell=True)
        cm_values_from = cm_values.communicate()[0].decode()
    values_command = ['echo', cm_values_from + values]
    substr_command = "perl -pe 's{(?|\$\{([_a-zA-Z]\w*)\}|\$([_a-zA-Z]\w*))}{$ENV{$1}//$&}ge'"
    release_command = f"helm template {name} {chart_repo}/{chart_name} --version {chart_version} -n {namespace} --skip-tests --no-hooks -f -"
    diff_command = f"kubectl diff --server-side=false -n {namespace} -f -"
    full_values = subprocess.Popen(values_command, stdout=subprocess.PIPE)
    substr = subprocess.Popen(
        substr_command, stdin=full_values.stdout, stdout=subprocess.PIPE, shell=True, env=os.environ.copy())
    release = subprocess.Popen(
        release_command, stdin=substr.stdout, stdout=subprocess.PIPE, shell=True)
    diff = subprocess.Popen(
        diff_command, stdin=release.stdout, stdout=subprocess.PIPE, shell=True)
    full_values.stdout.close()
    substr.stdout.close()
    release.stdout.close()
    return diff.communicate()[0].decode()


def main(args):
    yaml_file = args[1]
    sources_folder = args[2]

    parsed_data = parse_yaml_file(yaml_file)

    if parsed_data:
        name, namespace, chart_repo, chart_version, chart_name, values, values_from = parsed_data
    else:
        logging.error("Error in parsing the YAML file")
        sys.exit(1)

    sources_map = process_folder(sources_folder)

    add_helm_repo(chart_repo, sources_map[chart_repo]
                  ['url'], secret=sources_map[chart_repo]['secret'])

    diff = get_helm_diff(name, chart_repo, chart_name,
                         chart_version, namespace, values, values_from)
    print(diff)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        logging.error("Invalid number of arguments")
        logging.info(
            "Usage: python3 program.py <helmrelease-file> <sources-dir>")
        sys.exit(1)

    main(sys.argv)
