**Chromecrawler_terraform** is a Terraform module. It creates an API with following capabilities:
 - Execute selenium webdriver script inside Lambda function with headless chrome
 - Trigger execution of selenium script by API call
 - API could return a screenshot as a png image after execution of selenium script

# Configuration

Incude as a module into your terraform file
```
module "chromecrawler_terraform" {
  source = "github.com/maxmode/chromecrawler_terraform"

  # Any string. Is used to unique resource naming.
  environment = "prod"
  
  # API version/stage. Will ba a prefix in your API
  api_stage = "v"

  # Mapping between API URIs and selenium scripts
  # API path slug(suffix) => Path to a test script, relative to this file
  api_slug_to_file = {
    "slug1" = "./tests/node_webdriver_test.js"
  }
}

# This will output URL of generated API. Add to this URL your slug, and associated Lambda function will be triggered and will run needed script
output "API_BASE_URI" {
  value = "${module.chromecrawler_terraform_grafana.base_url}"
}
```

# Requirements
 - AWS Account
 - `Terraform`
 - `node.js` + `npm`
 - `modclean` npm modules for reducing function size

# Deployment

1. Run `terraform get` to install newly added module

1. Find a folder of added module and execute following commands in folder `lambda/chromecrawler`:
    ```
    ./scripts/fetch-dependencies.sh
    npm i -g modclean
    modclean --patterns="default:*"
    ``` 

3.  Run `terraform apply`. This command will create API Gateway, Lambda function and other resources defined in module **chromecrawler_terraform**

# Sample test
Tests are executed in a sandbox environment, so only limited JS environment is available:
```javascript

// Sample selenimum-webdriver script that visits google.com
// This uses the selenium-webdriver 3.4 package.
// Docs: https://seleniumhq.github.io/selenium/docs/api/javascript/module/selenium-webdriver/index.html
// $browser = webdriver session
// $driver = driver libraries
// console.log will output to AWS Lambda logs (via Cloudwatch)
// callback is a callback from Lambda's index.handler. Execution of the callback will return response to API Gateway

console.log('About to visit google.com...');
$browser.get('http://www.google.com/ncr');
$browser.findElement($driver.By.name('btnK')).click();
$browser.wait($driver.until.titleIs('Google'), 1000);
$browser.getTitle().then(function(title) {
    console.log("title is: " + title);
    console.log('Finished running script!');
});

```

# How to make and return a screenshot via API?
 
Variable `callback`, available in SDK, - is a a callback of Lambda function.
By triggering it Lambda may return response body, status code and headers to API Gateway. 

Sample function that will make a screenshot and return it to API
```javascript
function takeScreenshotAndClose(statusCode = 200) {
    $browser.getTitle().then(function(title) {
        console.log("Screenshot will be made for page with title: " + title);
        $browser.takeScreenshot().then(
            function(image, err) {
                callback(null, {
                    statusCode: statusCode,
                    headers: {
                        'Content-Type': 'image/png'
                    },
                    body: image,
                    isBase64Encoded: true
                });
                console.log('---');
                console.log('Image size: ' + Math.round(image.length/1024) + 'Kb');
                console.log('---');
                console.log('Status code: ' + statusCode);
            }
        )
    });
}
```

# Credits
Based on https://github.com/smithclay/lambdium
