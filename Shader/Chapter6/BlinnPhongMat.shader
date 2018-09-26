// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Blinn-Phong" {
    Properties {
        // 材质的漫反射颜色
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
        // 材质的高光反射颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",range(8.0,256)) = 20
    }
    SubShader {
        Tags { "LightMode"="ForwardBase" }

        Pass {
            CGPROGRAM
            
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                // 定义顶点着色器输入
                struct a2v{
                    // 对象模型空间顶点
                    float4 vertex : POSITION;
                    // 顶点法线
                    float3 normal : NORMAL;
                };
                // 定义顶点着色器输出
                struct v2f{
                    // 对象裁剪空间顶点
                    float4 pos : SV_POSITION;
                    // 对象世界坐标下法线
                    float3 worldNormal : NORMAL;
                    // 对象世界坐标下的顶点
                    float4 worldPos : TEXCOORD0;
                };

                fixed4 _Diffuse;
                float _Gloss;
                fixed4 _Specular;

                v2f vert(a2v v){
                    v2f o;

                    // 顶点变换
                    o.pos = UnityObjectToClipPos(v.vertex);
 
                    // 获得在世界坐标下的顶点坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获得在世界坐标下的法线
                    o.worldNormal = mul((float3x3)unity_ObjectToWorld,v.normal);

                    return o;
                }

                fixed4 frag(v2f v) : SV_TARGET{

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                    // 获得归一化世界坐标下顶点法线
                    fixed3 worldNormal = normalize(v.worldNormal);

                    // 获得归一化光源方向
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                    // 获得光源颜色
                    fixed3 lightColor = _LightColor0.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = lightColor * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));

                    // // 获得反射方向
                    // fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));

                    // 获得观察方向
                    fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - v.worldPos.xyz);

                    // 获得Blinn模型中的单位矢量h
                    fixed3 halfDir = normalize(worldLightDir+viewDir);

                    // 计算Blinn-Phong高光反射模型
                    fixed3 Specular = lightColor * _Specular.rgb * pow(saturate(dot(halfDir,worldNormal)),_Gloss);

                    // 混合颜色
                    fixed3 color = diffuse + Specular + ambient;

                    return fixed4(color,1);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}