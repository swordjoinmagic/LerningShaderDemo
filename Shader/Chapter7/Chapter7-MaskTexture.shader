// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/MaskTexture" {
    Properties {
        _Color("Color",Color) = (1, 1, 1, 1)
        _MainTex("Main Tex",2D) = "white" {}
        _BumpMap("Normal Map",2D) = "bump" {}
        _BumpScale("Bump Scle",Float) = 1.0
        
        // 高光反射遮罩纹理
        _SpecularMask("SpecularMask",2D) = "white" {}
        // 用于控制遮罩影响度的系数
        _SpecularScale("SpecularScale",Float) = 1.0

        _Specular("Specular",Color) = (1, 1, 1, 1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"
                #include "UnityCG.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                float _BumpScale;
                sampler2D _SpecularMask;
                float4 _SpecularMask_ST;
                float _SpecularScale;
                fixed4 _Specular;
                float _Gloss;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float4 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float3 lightDir : TEXCOORD1;
                    float3 viewDir : TEXCOORD2;
                };

                v2f vert(a2v v){
                    v2f o;
				    o.pos = UnityObjectToClipPos(v.vertex);

                    o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                    TANGENT_SPACE_ROTATION;
                    o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                    o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    // 获得切线空间下的单位光源方向和观察方向
                    fixed3 tangentLightDir = normalize(i.lightDir);
                    fixed3 tangentViewDir = normalize(i.viewDir);

                    // 获得法线纹理中的法线
                    fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
                    tangentNormal.xy *= _BumpScale;
                    tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                    // 对纹理贴图进行采样
                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                    // 计算漫反射光照
                    fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));

                    fixed3 halftDir = normalize(tangentLightDir+tangentViewDir);

                    // 获得遮罩纹理,该遮罩纹理使用纹理Color中的r分量作为掩码，
                    // 如果r为1，那么说明不影响此处（当前uv坐标下）的高光反射
                    // 如果r为0，说明完全遮盖此处的高光反射，
                    // r在[0,1]之间，则是部分遮盖
                    fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;

                    // 计算高光反射
                    fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(tangentNormal,halftDir)),_Gloss) * specularMask;

                    // 获得环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                    return fixed4(ambient + diffuse + specular,1.0);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}