Shader "sjm/shader Demo/diffuse demo" {
    Properties {
        _Diffuse("Diffuse",Color) = (1, 1, 1, 1)
    }
    SubShader {
        Pass {
            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "Lighting.cginc"

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float3 worldNormal : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                };

                fixed4 _Diffuse;

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);

                    o.worldNormal = UnityObjectToWorldNormal(v.normal);
                    o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed3 worldNormal = normalize(i.worldNormal);
                    fixed3 worldPos = normalize(i.worldPos);

                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos)); 

                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0,dot(worldNormal,worldLightDir));

                    return fixed4(diffuse+ambient,1.0);
                }



            ENDCG

        }
    }
    FallBack "Diffuse"
    
}