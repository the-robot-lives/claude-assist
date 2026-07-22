FROM nginx:1.27-alpine AS production

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY web/ /usr/share/nginx/html/
COPY quiz-app/dist/index.html /usr/share/nginx/html/quiz/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
