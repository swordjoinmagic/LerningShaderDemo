Shader "Unity Shaders Book/Chapter 11/EdgeDetection" {
    Properties {
        _MainTex("Main Tex",2D) = "white" {}
        // 当EdgeOnly为0时,边缘会叠加到原渲染图像上,
        // 当edgesOnly为1时,会只显示边缘
        _EdgeOnly("Edge Only",Float) = 1
        _EdgeColor("Edge Color",Color) = (0, 0, 0, 1)
        _BackgroundColor("Background Color",Color) = (1, 1, 1, 1)
    }
    SubShader {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        ZWrite Off
        ZTest Always
        Cull Off
        Pass {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                // 纹理对应的每个纹素的大小,用来后续计算相邻纹理坐标用
                float4 _MainTex_TexelSize;
                float _EdgeOnly;
                fixed4 _EdgeColor;
                fixed4 _BackgroundColor;

                struct a2v{
                    float4 vertex : POSITION;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float2 uv[9] : TEXCOORD0;
                };

                v2f vert(a2v v){
                    v2f o;
                    o.pos = UnityObjectToClipPos(v.vertex);

                    float2 uv = v.texcoord;

                    // 左下纹理坐标
                    o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,-1);
                    // 下纹理坐标
                    o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0,-1);
                    // 右下纹理坐标
                    o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1,-1);
                    // 左纹理坐标
                    o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,0);
                    // 原点
                    o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0,0);
                    // 右纹理坐标
                    o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1,0);
                    // 左上纹理坐标
                    o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1,1);
                    // 上纹理坐标
                    o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0,1);
                    // 右上纹理坐标
                    o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,1);

                    return o;
                }

                half Sobel(v2f i){
                    // Gx算子
                    const half Gx[9] = {
                        -1,-2,-1,
                        0 , 0 ,0,
                        1 , 2 ,1 
                    };
                    // Gy算子
                    const half Gy[9] = {
                        -1,0,1,
                        -2,0,2,
                        -1,0,1
                    };
 
                    half texColor;
                    half edgeX = 0;
                    half edgeY = 0;
                    for(int it=0;it<9;it++){
                        texColor = Luminance(tex2D(_MainTex,i.uv[it]).rgb);
                        edgeX += texColor * Gx[it];
                        edgeY += texColor * Gy[it];
                    }
                    half edge = 1-abs(edgeX) - abs(edgeY);

                    return edge;
                } 

                fixed4 frag(v2f i) : SV_TARGET{
                    half edge = Sobel(i);

                    fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[4]),edge);
                    fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);
                    return lerp(withEdgeColor,onlyEdgeColor,_EdgeOnly);
                }


            ENDCG
        }
    }
    FallBack Off
    
}