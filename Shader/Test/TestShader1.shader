Shader "LerningShaderDemo/TestShader1" {
	Properties {
		// 数字和滑动条
		_Int("Int",Int) = 2
		_Float("Float",Float) = 1.5
		_Range("_Range",Range(0.0,5.0)) = 3.0
		// 颜色以及向量
		_Color("Color",Color) = (1, 1, 1, 1)
		_Vector("Vector",Vector) = (2, 3, 6, 1)
		// 纹理
		_2D("2D",2D) = "defaulttexture" {}
		_Cube("Cube",Cube) = "defaulttexture" {}
		_3D("3D",3D) = "defaulttexture" {}
	}


	FallBack "Diffuse"	
}