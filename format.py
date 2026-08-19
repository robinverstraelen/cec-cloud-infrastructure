import json

CONSOLE_URL = "https://sue-aws-student-01.signin.aws.amazon.com/console"


def write_credentials(entries, filename):
    with open(filename, 'w') as outfile:
        json.dump(
            [{**e, "aws_console_url": CONSOLE_URL} for e in entries],
            outfile,
            indent=2,
        )


# Read the terraform outputs (terraform output -json > outputs.json)
with open('outputs.json', 'r') as file:
    json_data = json.load(file)

students = json_data['lab_vm_access_info']['value']
groups = json_data['group_vm_access_info']['value']

write_credentials(students, 'student_credentials.json')
write_credentials(groups, 'group_credentials.json')

print(f"Wrote {len(students)} students to student_credentials.json "
      f"and {len(groups)} groups to group_credentials.json")
