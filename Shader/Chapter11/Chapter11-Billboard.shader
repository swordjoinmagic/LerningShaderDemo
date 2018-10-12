Shader "Unity Shaders Book/Chapter 11/Billboard" {
    Properties {
        // 用于广告牌显示的透明纹理
        _MainTex("Main Tex",2D) = "white" {}
        // 用于控制整体颜色
        _Color("Color",Color) = (1, 1, 1, 1)
        // 用于调整是固定法线还是固定指向上的方向,
        // 即约束垂直方向的程度
        _VerticalBillboarding("Vertical Restraints",Range(0,1)) = 1
    }
    SubShader {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True" } 
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed4 _Color;
                fixed _VerticalBillboarding;

                struct a2v{
                    float4 vertex : POSITION;
                    float2 texcoord : TEXCOORD0;
                };

                struct v2f{
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                // billboard技术的核心在于让每个顶点都旋转到面向玩家的角度
                // 所以我们在billboard中需要建立一个新的坐标空间轴,在这里我称它为
                // 模型旋转坐标轴,
                // 模型旋转坐标轴以摄像机视角方向,以物体向右的方向,表面法线为正交基
                v2f vert(a2v v){
                    v2f o;

                    // 首先为模型旋转坐标轴定义在模型空间下的原点
                    float3 center = float3(0,0,0);
                    // 使用内置变量获取模型空间下的视角位置
                    float3 viwer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));

                    //========================
                    //计算正交矢量

                    // 根据观察位置和锚点计算目标法线方向
                    float3 normalDir = viwer - center;

                    // 当_VerticalBillboarding为1时,表示法线方向固定为视角方向
                    // `当_VerticalBillboarding为0时,表示法线方向固定为(0,1,0)
                    normalDir.y = normalDir.y * _VerticalBillboarding;
                    normalDir = normalize(normalDir);

                    float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);
                    float3 rightDir = normalize(cross(upDir,normalDir));
                    upDir = normalize(cross(normalDir,rightDir));

                    float3 centerOffs = v.vertex.xyz - center;
                    float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir*centerOffs.z;

                    o.pos = UnityObjectToClipPos(localPos);
                    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    fixed4 c = tex2D(_MainTex,i.uv);
                    c.rgb *= _Color.rgb;
                    return c;
                }

            ENDCG
        }
    }
    FallBack "Diffuse"
    
}