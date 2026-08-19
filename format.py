import json

CONSOLE_URL = "https://sue-aws-student-01.signin.aws.amazon.com/console"


def format_student_info(data, url=CONSOLE_URL):
    output = []
    for student in data:
        formatted = f"""
AWS Console URL: {url}
AWS Console Password: {student['aws_console_password']}
AWS User: {student['aws_iam_user']}
VM Name: {student['instance_name']}
Huidige Publiek IP: {student['public_ip']}
SSH Private Key: "{student['ssh_private_key']}"
"""
        output.append(formatted)
    return "\n".join(output)


# Read the terraform outputs (terraform output -json > outputs.json)
with open('outputs.json', 'r') as file:
    json_data = json.load(file)

students = json_data['lab_vm_access_info']['value']
groups = json_data['group_vm_access_info']['value']

formatted_output = format_student_info(students)
print(formatted_output)

with open('students_access_info.txt', 'w') as outfile:
    outfile.write(formatted_output)

with open('group_credentials.json', 'w') as outfile:
    json.dump(
        [{**g, "aws_console_url": CONSOLE_URL} for g in groups],
        outfile,
        indent=2,
    )

print(f"Wrote {len(students)} students to students_access_info.txt "
      f"and {len(groups)} groups to group_credentials.json")
