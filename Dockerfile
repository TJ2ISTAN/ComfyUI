FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime

RUN apt update -y
RUN DEBIAN_FRONTEND=noninteractive TZ=America/Chicago apt install -y sudo build-essential iproute2 wget ncurses-bin figlet toilet vim nano tig curl git htop zsh ffmpeg tmux jq ca-certificates gnupg

RUN mkdir -p /etc/apt/keyrings

RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt update 
RUN apt install -y nodejs 

RUN cd /root && npm install request chokidar form-data ws glob express axios @aws-sdk/client-s3 @aws-sdk/credential-providers dotenv bull

RUN pip install gradio opencv-python kornia loguru scikit-image onnx onnxruntime-gpu lpips ultralytics python_bidi arabic_reshaper 
RUN pip install torchvision gitpython timm addict yapf insightface numba

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY ./.zshrc /root/.zshrc

WORKDIR  /workspace/

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && cd ComfyUI
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git /workspace/ComfyUI/custom_nodes/ComfyUI-Manager


WORKDIR /workspace
RUN cd /workspace/ComfyUI && pip install -r requirements.txt
RUN cd /workspace/ComfyUI/custom_nodes/ComfyUI-Manager && pip install -r requirements.txt

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

RUN wget https://github.com/mikefarah/yq/releases/download/v4.35.2/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

COPY ./extra_model_paths.yml /extra_model_paths.yml
COPY ./extra_downloads.yml /extra_downloads.yml

COPY ./magic /bin/magic
COPY ./.env /root/.env
COPY ./heartbeat.js /root/heartbeat.js

RUN mv /opt/conda/bin/ffmpeg /opt/conda/bin/ffmpeg-ancient
RUN ln -s /usr/bin/ffmpeg /opt/conda/bin/ffmpeg
WORKDIR /storage/ComfyUI
RUN echo '0.3.6' > /version

RUN pip install openai==0.28 numexpr

CMD ["/bin/magic"]
