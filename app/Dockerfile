FROM public.ecr.aws/lambda/nodejs:20

COPY package.json ${LAMBDA_TASK_ROOT}/

RUN cd ${LAMBDA_TASK_ROOT} && npm install

COPY . ${LAMBDA_TASK_ROOT}/


CMD [ "src/handler.handler" ]