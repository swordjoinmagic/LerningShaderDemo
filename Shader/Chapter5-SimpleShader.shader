// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chpater 5/Simple Shader" {
	Properties {
		// 声明一个Color类型的属性
		_Color ("Color Tint",Color) = (0, 0, 0, 0)
	}
	SubShader {
		Pass {
			CGPROGRAM

				// 获得属性中的_Color变量
				fixed4 _Color;

				// 声明顶点着色器函数vert和片元着色器函数frag
				#pragma vertex vert
				#pragma fragment frag

				// 使用一个结构体来定义顶点着色器的输入
				struct a2v{
					// POSITION语义告诉Unity,用模型空间的顶点坐标填充vertex变量
					float4 vertex : POSITION;
					// NORMAL 语义告诉Unity,用模型空间的法线方向填充normal变量
					float3 normal : NORMAL;
					// TEXCOORD 语义告诉Unity,用模型的第一套纹理坐标填充texcoord变量
					float4 texcoord : TEXCOORD;
				};

				// 使用一个结构体来定义顶点着色器的输出
				struct v2f{
					// SV_POSITION 语义告诉Unity,pos里包含了顶点在裁剪空间中的位置信息
					float4 pos : SV_POSITION;
					// COLOR0 语义用于存储颜色信息
					fixed3 color : COLOR0;

				};

				/*
				* 将顶点从模型空间变换至裁剪空间的函数
				*/
				v2f vert(a2v v){
					// 声明输出结构
					v2f o;
					// 使用v.vertex来访问模型空间的顶点坐标
					o.pos = UnityObjectToClipPos(v.vertex);
					// v.normal包含了顶点的法线方向,其分量范围在[-1.0,1.0],
					// 下面的代码把分量范围映射到了[0.0,1.0],
					// 存储到o.color中传递给片元着色器
					o.color = v.normal * 0.5 + fixed3(0.5,0.5,0.5);
					
					return o;
				}

				
				fixed4 frag(v2f i) : SV_TARGET{
					fixed3 c = i.color;

					// 使用_Color属性来控制输出的颜色
					c *= _Color.rgb;

					// 将插值之后的i.color显示到屏幕上
					return fixed4(c,1.0);
				}

			ENDCG
		}
	}
}