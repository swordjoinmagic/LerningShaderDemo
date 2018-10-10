// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unity Shaders Book/Chapter 9/AttenuationAndShadowUseBuildInFunctions" {
    Properties {
        // 用于控制高光反射材质的颜色
        _Specular("Specular",Color) = (1, 1, 1, 1)
        // 用于控制漫反射材质颜色
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
        // 用于控制高光反射的光泽度
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {

		Tags { "RenderType"="Opaque" }

        // BasePass，用于处理平行光的光照渲染
        Pass {
            
            // 使用前照渲染路径
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                // 使用预编译指令multi_compile_fwdbase
                // 来使unity正确赋值光照衰减等光照变量
                #pragma multi_compile_fwdbase
                
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                float _Gloss;
                fixed4 _Specular;
                fixed4 _Diffuse;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 worldNormal : TEXCOORD1;
                    SHADOW_COORDS(2)
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    // 计算阴影纹理
                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); 

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldLightDir,worldNormal));

                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); 
                    fixed3 halfDir = normalize(worldLightDir+viewDir);

                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    return fixed4(diffuse+(specular+ambient)*atten,1.0);
                }

            ENDCG
        } 

        // Additional Pass,逐像素光源光照的计算pass
        Pass{
            Tags{ "LightMode" = "ForwardAdd" }
            Blend One One

            CGPROGRAM
                
                // 使用预编译指令multi_compile_fwdadd
                // 来使unity正确赋值光照衰减等光照变量
                #pragma multi_compile_fwdadd
                
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
    			#include "AutoLight.cginc"

                float _Gloss;
                fixed4 _Specular;
                fixed4 _Diffuse;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldPos : TEXCOORD0;
                    float3 worldNormal : TEXCOORD1;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);

                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);

                    // 判断要处理的光源类型，如果是平行光，那么该光源方向是固定的，
                    // 如果是其他光源类型，该光源的方向为当前光源的位置到目标物体的方向
                    #ifdef USING_DIRECTIONAL_LIGHT
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                    #else
                        fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    #endif
                    
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldLightDir,worldNormal));

                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); 
                    fixed3 halfDir = normalize(worldLightDir+viewDir);

                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)),_Gloss);

                    // 光照衰减值，对于平行光来说，该值一直为1
                    #ifdef USING_DIRECTIONAL_LIGHT
                        fixed atten = 1.0;
                    #else
                        float3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                        fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #endif

                    return fixed4(diffuse+(specular+ambient)*atten,1.0);
                }
            ENDCG
        }
    }
 
    FallBack "Diffuse"
    
}