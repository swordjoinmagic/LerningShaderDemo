// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 5/False Color" {
    // 使用假彩色对Shader进行调试

    Properties {
        
    }
    SubShader {
        pass{
            CGPROGRAM
                // 定义顶点,片元着色器函数
				#pragma vertex vert
				#pragma fragment frag

                // 导入Unity的内置shader函数包
                #include "UnityCG.cginc"

                // 定义顶点着色器的输出结构体
                struct v2f{
                    float4 pos : SV_POSITION;
                    fixed4 color : COLOR0;
                };

                // 顶点着色器,使用Unity内置结构体appdata_full作为参数传递(包含模型的所有基本信息)
                v2f vert(appdata_full v){
                    // 声明输出结构体
                    v2f o;

                    o.pos = UnityObjectToClipPos(v.vertex);
                    // // 可视化法线方向
                    // o.color = fixed4(v.normal*0.5 + fixed3(0.5,0.5,0.5),1.0);
                    // // 可视化切线方向
                    // o.color = fixed4(v.tangent.xyz*0.5 + fixed3(0.5,0.5,0.5),1.0);
                    // 可视化副切线方向
                    // fixed3 binormal = cross(v.normal,v.tangent.xyz) * v.tangent.w;
                    // o.color = fixed4(binormal*0.5+fixed3(0.5,0.5,0.5),1.0);
                    // // 可视化第一组纹理坐标
                    // o.color = fixed4(v.texcoord.xy,0.0,1.0);
                    // // 可视化第二组纹理坐标
                    // o.color = fixed4(v.texcoord1.xy,0.0,1.0);
                    
                    // // 可视化第1组纹理坐标的小数部分
                    // o.color = frac(v.texcoord);
                    // if(any(saturate(v.texcoord) - v.texcoord)){
                    //     o.color.b = 0.5;
                    // }
                    // o.color.a = 1.0;

                    // 可视化第2组纹理坐标的小数部分
                    o.color = frac(v.texcoord1);
                    if(any(saturate(v.texcoord1) - v.texcoord1)){
                        o.color.b = 0.5;
                    }
                    o.color.a = 1.0;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET{
                    return i.color;
                }

            ENDCG
            
        }    
    }
    FallBack "Diffuse"
    
}