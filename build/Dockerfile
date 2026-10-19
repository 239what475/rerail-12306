# 通用服务镜像：--build-arg SERVICE=<gateway|user|ticket|order|pay>
# 构建上下文 = 载体仓库根目录（CI 里 checkout nageoffer/12306）
# CI 环境用 maven:3.9-temurin17 + eclipse-temurin:17-jre（公共镜像，无需 ACR）
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /src
COPY . .
# 载体项目只有 gateway 的 pom 声明了 spring-boot 插件（其余服务平时靠 IDE 直跑）。
# 给四个业务服务的 pom 补上 repackage 绑定，再全量 install。
RUN --mount=type=cache,target=/root/.m2 \
    for s in user ticket order pay; do \
      awk -v blk='    <build>\n        <plugins>\n            <plugin>\n                <groupId>org.springframework.boot</groupId>\n                <artifactId>spring-boot-maven-plugin</artifactId>\n                <version>3.1.0</version>\n                <executions>\n                    <execution>\n                        <goals>\n                            <goal>repackage</goal>\n                        </goals>\n                    </execution>\n                </executions>\n            </plugin>\n        </plugins>\n    </build>' 'BEGIN{done=0} { if (!done && $0 ~ /^<\/project>/) { print blk; done=1 } print }' \
        services/${s}-service/pom.xml > /tmp/p.xml && mv /tmp/p.xml services/${s}-service/pom.xml; \
    done && \
    mvn -B install -DskipTests -q

FROM eclipse-temurin:17-jre
ARG SERVICE
ENV TZ=Asia/Shanghai JAVA_OPTS=""
COPY --from=builder /src/services/${SERVICE}-service/target/*.jar /app/app.jar
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
