// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Specular Pixel-Level" {
    Properties {
        // 物体的光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
        // 材质的漫反射颜色
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
        // 材质的高光反射颜色
        _Specular ("Specular",Color) = (1, 1, 1, 1)
    }
    SubShader {
        Tags{"LightMode"="ForwardBase"}
        pass{
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                // 定义输入给顶点着色器的结构体
                struct a2v{
                    // 顶点位置
                    float4 vertex : POSITION;
                    // 顶点法线
                    float3 normal : NORMAL;
                };

                // 定义输入给片元着色器的结构体
                struct v2f{
                    // 裁剪空间下的物体顶点位置
                    float4 pos : SV_POSITION;
                    // 世界坐标下的顶点法线
                    float3 worldNormal : TEXCOORD0;
                    // 世界坐标下的物体顶点位置
                    float4 worldPos : TEXCOORD1;
                };

                float _Gloss;
                fixed4 _Diffuse;
                fixed4 _Specular;

                v2f vert(a2v v){
                    v2f o;

                    // 将对象空间坐标下的顶点转移到裁剪坐标下
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得世界坐标下的单位向量法线
                    o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);

                    // 将世界坐标下的顶点位置赋给worldPos
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    return o;
                }

                fixed4 frag(v2f v) : SV_TARGET{
                    
                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                    // 获得世界坐标下的单位向量光源方向
                    fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                    // 获得世界坐标下的单位向量法线
                    fixed3 worldNormal = normalize(v.worldNormal);

                    // 获得光源颜色
                    fixed3 lightColor = _LightColor0.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = lightColor.rgb * _Diffuse.rgb * saturate(dot(worldLight,worldNormal));

                    // 获得反射方向
                    // fixed3 reflectDir = normalize(2*dot(worldLight,worldNormal)*worldLight - worldNormal);
                    fixed3 reflectDir = normalize(reflect(-worldLight,worldNormal));

                    // 获得观察方向
                    fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - v.worldPos.xyz);

                    // 计算高光反射
                    fixed3 specular = lightColor.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                    // 颜色混合
                    fixed3 color = ambient + diffuse + specular;

                    return fixed4(color,1.0);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
    
}