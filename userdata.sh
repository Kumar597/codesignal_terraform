#! /bin/bash
yum update -y
yum install httpd 
cat > /var/www/html/index.html <<EOF
  <!DOCTYPE html>
<html>
<body onload="myFunction()">

    <p>Hello World</p>
    <input type="text" id="demo"/>

<script>
function myFunction() {
document.getElementById('demo').value= Date();
}
</script>
</body>
</html> 
EOF
systemctl start httpd
systemctl enable httpd