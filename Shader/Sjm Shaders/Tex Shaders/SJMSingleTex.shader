// 带有阴影,漫反射,高光反射,支持多光源照射,单张2D纹理效果的shader
Shader "SJM/SingleTex" {
    Properties {
        // 主纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 控制整体颜色
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        // 控制高光反射颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {

        Tags { "RenderType" = "Opaque" }

        // BasePass,支持平行光照射
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM

                // Base前向渲染的预编译指令
                #pragma multi_compile_fwdbase

                #pragma vertex vert
                #pragma fragment frag

                // 导入用于计算阴影和环境光的cg包
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;     // 用于表示纹理的缩放以及偏移(offset)
                fixed4 _Color;
                fixed4 _Specular;
                float _Gloss;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;

                    // 模型的0号纹理
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    // 世界坐标下的法线,用于在片元着色器中计算漫反射,高光反射
                    float3 worldNormal : TEXCOORD0;
                    // 世界坐标下的顶点坐标,用于在片元着色器中计算光源照向方向和顶点的视角方向(ViewDir)
                    float3 worldPos : TEXCOORD1;
                    // 经过缩放和偏移后的纹理坐标,用于对纹理进行采样
                    float2 uv : TEXCOORD2;
                    
                    // 用于计算阴影
                    SHADOW_COORDS(3)
                };

                v2f vert(a2v v){
                    v2f o;

                    // 变换模型坐标到裁剪空间下
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得世界坐标下的顶点坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获得世界坐标下的法线坐标
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    // 对uv坐标进行缩放及偏移
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                    // 阴影计算
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 归一化法线
                    fixed3 worldNormal = normalize(i.worldNormal);
                    // 获得归一化光源方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                    // 获得归一化的顶点的视角方向
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                    // 对纹理进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                    // 计算Blinn-Phong光照模型的half矢量
                    fixed3 halfDir = normalize(worldLightDir+worldViewDir);

                    // 计算高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    // 混合高光反射,漫反射,阴影颜色
                    fixed3 color = ambient + (diffuse+specular)*atten;

                    return fixed4(color,1.0);
                }

            ENDCG
        }

        // AddPass,支持点光源,聚光灯照射
        Pass{
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One

            CGPROGRAM
                
                // Add前向渲染
                #pragma multi_compile_fwdadd

                #pragma vertex vert
                #pragma fragment frag

                // 导入用于计算阴影和环境光的cg包
                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;     // 用于表示纹理的缩放以及偏移(offset)
                fixed4 _Color;
                fixed4 _Specular;
                float _Gloss;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;

                    // 模型的0号纹理
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    // 世界坐标下的法线,用于在片元着色器中计算漫反射,高光反射
                    float3 worldNormal : TEXCOORD0;
                    // 世界坐标下的顶点坐标,用于在片元着色器中计算光源照向方向和顶点的视角方向(ViewDir)
                    float3 worldPos : TEXCOORD1;
                    // 经过缩放和偏移后的纹理坐标,用于对纹理进行采样
                    float2 uv : TEXCOORD2;
                    
                    // 用于计算阴影
                    SHADOW_COORDS(3)
                };

                v2f vert(a2v v){
                    v2f o;

                    // 变换模型坐标到裁剪空间下
                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 获得世界坐标下的顶点坐标
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 获得世界坐标下的法线坐标
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    // 对uv坐标进行缩放及偏移
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                    // 阴影计算
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 归一化法线
                    fixed3 worldNormal = normalize(i.worldNormal);
                    // 获得归一化光源方向
                    #ifdef USING_DIRECTIONAL_LIGHT
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    #else
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    #endif
                    // 获得归一化的顶点的视角方向
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                    // 对纹理进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                    // 计算Blinn-Phong光照模型的half矢量
                    fixed3 halfDir = normalize(worldLightDir+worldViewDir);

                    // 计算高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    // fixed atten = 1;

                    // 混合高光反射,漫反射,阴影颜色
                    fixed3 color = ambient + (diffuse+specular)*atten;

                    return fixed4(color,1.0);
                }



            ENDCG
        }
    }
    FallBack "Diffuse"
    
}