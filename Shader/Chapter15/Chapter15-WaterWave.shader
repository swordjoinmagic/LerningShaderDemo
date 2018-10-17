Shader "Unity Shaders Book/Chapter 15/WaterWave" {
    Properties {
        // 用于控制水面颜色
        _Color("Main Color",Color) = (0, 0.15, 0.115, 1)
        // 水面博文材质纹理
        _MainTex("Base (RGB)",2D) = "white" {}
        // 由噪声纹理生成的法线纹理
        _WaveMap("Wave Map",2D) = "bump" {}
        // 用于模拟反射的立方体纹理
        _CubeMap("Environment Cubemap",Cube) = "_SkyBox" {}
        // 法线纹理在X和Y方向上的平移速度
        _WaveXSpeed("Wave Horiantoal Speed",Range(-0.1,0.1)) = 0.01
        _WaveYSpeed("Wave Vertical Speed",Range(-0.1,0.1)) = 0.01
        // 用于控制模拟折射时图像的扭曲程度
        _Distortion("Distortion",Range(0,100)) = 10
    }
    SubShader {
        // 之所以设置该shader在所有不透明物体后绘制是因为要使用GrapPass来对屏幕进行取样模拟折射
        Tags{ "Queue"="Transparent" "RenderType"="Opaque" }

        GrabPass{"_RefractionTex"}

        Pass {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #pragma multi_compile_fwdbase

                #include "Lighting.cginc"
                #include "AutoLight.cginc"

                fixed4 _Color;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _WaveMap;
                float4 _WaveMap_ST;
                samplerCUBE _CubeMap;
                fixed _WaveXSpeed;
                fixed _WaveYSpeed;
                float _Distortion;
                sampler2D _RefractionTex;
                float4 _RefractionTex_TexelSize;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 texcoord : TEXCOORD0;
                    float4 tangent : TANGENT;
                };
                struct v2f{
                    float4 pos : SV_POSITION;
                    float4 scrPos : TEXCOORD0;
                    float4 uv : TEXCOORD1;
                    float4 TtoW0 : TEXCOORD2;
                    float4 TtoW1 : TEXCOORD3;
                    float4 TtoW2 : TEXCOORD4;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.scrPos = ComputeGrabScreenPos(o.pos);

                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_WaveMap);

                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = mul(unity_ObjectToWorld,v.tangent); 

                    // 计算副切线
                    fixed3 worldBinNormal = cross(worldNormal,worldTangent) * v.tangent.w;

                    // 计算 切线-世界 变换矩阵,将 切线，副切线，法线 按列摆放
                    o.TtoW0 = float4(worldTangent.x,worldBinNormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinNormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinNormal.z,worldNormal.z,worldPos.z);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                    float2 speed = _Time.y * float2(_WaveXSpeed,_WaveYSpeed);

                    fixed3 bump1 = UnpackNormal(tex2D(_WaveMap,i.uv.zw+speed)).xyz;
                    fixed3 bump2 = UnpackNormal(tex2D(_WaveMap,i.uv.zw-speed)).xyz;
                    fixed3 bump = normalize(bump1 + bump2);
                    // fixed3 bump = normalize( UnpackNormal(tex2D(_WaveMap,i.uv.zw)).xyz);
                    // fixed3 bump = normalize(bump1);

                    float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                    i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
                    fixed3 refrCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;

                    // 将法线变换到世界坐标空间下
                    bump = normalize( half3( dot(i.TtoW0.xyz,bump) , dot(i.TtoW1.xyz,bump) , dot(i.TtoW2.xyz,bump) ) );
                    fixed4 texColor = tex2D(_MainTex,i.uv.xy+speed);
                    fixed3 reflDir = reflect(-viewDir,bump);
                    fixed3 reflCol = texCUBE(_CubeMap,reflDir).rgb * texColor.rgb * _Color.rgb;

                    fixed fresnel = pow(1-saturate(dot(viewDir,bump)),4);

                    fixed3 finalColor = reflCol * fresnel + refrCol * (1-fresnel);

                    return fixed4(finalColor,1);
                }

            ENDCG
        }

    }
    FallBack "Diffuse"
    
}