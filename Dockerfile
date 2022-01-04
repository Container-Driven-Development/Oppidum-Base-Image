ARG BASE_IMAGE_VERSION

FROM alpine:${BASE_IMAGE_VERSION} as FETCHER

ARG KUSTOMIZE_VERSION=v3.8.4
ARG KUSTIMIZE_HELM_PLUGIN=v0.9.1

RUN wget -O- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xvz -C /usr/local/bin/
RUN chmod +x /usr/local/bin/kustomize
RUN mkdir -p /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer && \
    wget -O- https://github.com/mgoltzsche/helm-kustomize-plugin/releases/download/${KUSTIMIZE_HELM_PLUGIN}/helm-kustomize-plugin > /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer && \
    chmod u+x /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer

FROM alpine:${BASE_IMAGE_VERSION}

WORKDIR /workdir

ENTRYPOINT [ "/usr/local/bin/kustomize" ]

RUN apk add git --no-cache

COPY --from=FETCHER /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=FETCHER /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer /root/.config/kustomize/plugin/helm.kustomize.mgoltzsche.github.com/v1/chartrenderer/ChartRenderer