Shader "Unity Shaders Book/Chapter 10/Fresnel" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        // 菲涅尔反射程度
        _FresnelScale("Fresnel Scale",Range(0,1)) = 0.5
        // 立方体纹理
        _CubeMap("CubeMap",Cube) = "_SkyBox" {}
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
                #pragma multi_compile_fwbase

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                fixed4 _Color;
                fixed _FresnelScale;
                samplerCUBE _CubeMap;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                    float3 worldViewDir : TEXCOORD2;
                    float3 worldRefl : TEXCOORD3;
                    SHADOW_COORDS(4)
                };
                
                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                    o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

                    o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);

                    TRANSFER_SHADOW(o);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); 
                    fixed3 worldViewDir = normalize(i.worldViewDir);

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _Color.rgb * _LightColor0.rgb * max(0,dot(worldLightDir,worldNormal));

                    // 对cubemap进行采样
                    fixed3 reflection = texCUBE(_CubeMap,i.worldRefl).rgb;

                    // 计算菲涅尔反射
                    fixed fresnel = _FresnelScale+(1-_FresnelScale)*pow(1-dot(worldViewDir,worldNormal),5);

                    // 计算阴影
                    UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                    fixed3 color = ambient + lerp(diffuse,reflection,saturate(fresnel)) * atten;

                    return fixed4(color,1.0);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}