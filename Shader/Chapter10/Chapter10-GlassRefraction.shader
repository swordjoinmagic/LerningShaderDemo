Shader "Unity Shaders Book/Chapter 10/GlassRefraction" {
    Properties {
        // 该玻璃的材质纹理,默认为白色纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 法线纹理
        _BumpMap("Normal Map",2D) = "bump" {}
        // 立方体纹理
        _CubeMap("Cube Map",Cube) = "_Skybox" {}
        // 用于控制模拟折射时图像的扭曲程度
        _Distortion("Distortion",Range(0,100)) = 10
        // 控制折射程度
        _RefractAmount("RefractAmount",Range(0.0,1.0)) = 1.0
    }
    SubShader {
        Tags{ "Queue" = "Transparent" "RenderType" = "Opaque" }

        // 抓取屏幕图像的Pass,
        // Pass内的字符串表示抓取得到的屏幕图像将会被存入哪个纹理中.
        GrabPass{ "_RefractionTex" }
 
        Pass {

            Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                samplerCUBE _CubeMap;
                float _Distortion;
                fixed _RefractAmount;

                // 对应了在GrabPass中指定的纹理名称
                sampler2D _RefractionTex;
                // texelSize表示该纹理纹素大小,对于一个256*512的纹理,它的纹素大小为(1/256,1/512).
                // 对屏幕图像的采样坐标进行偏移时使用该变量
                float4 _RefractionTex_TexelSize;

                struct a2v{
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float4 uv : TEXCOORD0;
                    float4 TtoW0 : TEXCOORD1;
                    float4 TtoW1 : TEXCOORD2;
                    float4 TtoW2 : TEXCOORD3;
                    float4 scrPos : TEXCOORD4;
                };

                v2f vert(a2v v){
                    v2f o;

                    o.pos = UnityObjectToClipPos(v.vertex);

                    // 得到对应被抓取的屏幕图像的采样坐标,也就是当前坐标点在 屏幕图像上表现的像素 的 坐标
                    o.scrPos = ComputeGrabScreenPos(o.pos);

                    // 获得变化后的主纹理,法线纹理uv坐标
                    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                    o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                    fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    fixed3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                    // 获得 切线-世界 变换矩阵
                    o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                    fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos)); 

                    // 获得切线空间下的法线
                    fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));

                    // 计算因为折射发生的偏移(也就是造成 当前物体(透明的)后面的不透明物体的扭曲 的原因)
                    float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;

                    // 对抓取的屏幕图像的采样坐标进行偏移
                    i.scrPos.xy = offset + i.scrPos.xy;

                    // 对抓取的屏幕图像进行采样
                    fixed3 refrCol = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;
                    // fixed3 refrCol = fixed3(1,1,1);

                    // 将该法线转变到世界坐标下
                    bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

                    // 获得反射方向
                    fixed3 reflDir = reflect(-worldViewDir,bump);

                    // 对主纹理进行采样
                    fixed4 texColor = tex2D(_MainTex,i.uv.xy);

                    // 获得反射颜色
                    fixed3 reflCol = texCUBE(_CubeMap,reflDir).rgb * texColor.rgb;

				    fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

                    return fixed4(finalColor,1);
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}
