import json

def format_student_info(data, url="https://sue-aws-student-01.signin.aws.amazon.com/console"):
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

# Read the JSON file
with open('outputs_decrypted.json', 'r') as file:
    json_data = json.load(file)

# Extract the value array
students = json_data['lab_vm_access_info']['value']

# Generate the formatted output
formatted_output = format_student_info(students)

# Print or save the output
print(formatted_output)

# Optionally, save to a file
with open('students_access_info.txt', 'w') as outfile:
    outfile.write(formatted_output)
