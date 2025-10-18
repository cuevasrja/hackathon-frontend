if cd flutter; 
    then git pull && cd .. ; 
else 
    git clone https://github.com/flutter/flutter.git; 
fi && ls && flutter/bin/flutter doctor && flutter/bin/flutter clean && flutter/bin/flutter config --enable-web

if [ $API_BASE_URL ]; then
    echo "API_BASE_URL is set to $API_BASE_URL"
    echo "API_BASE_URL=$API_BASE_URL" > .env
else
    echo "API_BASE_URL is not set. Please set it before running the build."
    exit 1
fi