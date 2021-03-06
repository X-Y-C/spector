// ----------------------------------------------------------------------
// Copyright (c) 2016, The Regents of the University of California All
// rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
// 
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
// 
//     * Neither the name of The Regents of the University of California
//       nor the names of its contributors may be used to endorse or
//       promote products derived from this software without specific
//       prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL REGENTS OF THE
// UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
// OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
// TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// ----------------------------------------------------------------------
/*
 * Filename: sobel_subdimy_simdx8_base.cl
 * Version: 1.0
 * Description: Sobel filter OpenCL benchmark.
 * Author: Pingfan Meng
 */


__attribute__((reqd_work_group_size(BLOCKDIM_X,BLOCKDIM_Y,1)))
__kernel void sobel_filter(__global unsigned int * restrict image_in, __global unsigned int * restrict image_out)
{
   	
	__private int col_id=get_global_id(0)*SIMD_X;
	__private int row_id=get_global_id(1)*SUBDIM_Y;
	
	__private int loc_col_id=get_local_id(0)*SIMD_X;
	__private int loc_row_id=get_local_id(1)*SUBDIM_Y;
	
	__local int loc_buffer[BLOCKDIM_Y*SUBDIM_Y][BLOCKDIM_X*SIMD_X];

	__private int wx[3][3]={{-1,-2,-1},{0,0,0},{1,2,1}};
	__private int wy[3][3]={{-1,0,1},{-2,0,2},{-1,0,1}};

	__private int image_reg[3][2+SIMD_X];

	__private int8 resultx,resulty;

	__private int i,j,p;

	__private uint8 clamped;
	__private int8 temp;

	__private uint8 pixel,b,g,r,luma;




	#pragma unroll
	for (p=0;p<SUBDIM_Y;p++)
	{
		loc_buffer[loc_row_id+p][loc_col_id]=image_in[(row_id+p)*WIDTH+col_id];
		loc_buffer[loc_row_id+p][loc_col_id+1]=image_in[(row_id+p)*WIDTH+col_id+1];
		loc_buffer[loc_row_id+p][loc_col_id+2]=image_in[(row_id+p)*WIDTH+col_id+2];	
		loc_buffer[loc_row_id+p][loc_col_id+3]=image_in[(row_id+p)*WIDTH+col_id+3];
		loc_buffer[loc_row_id+p][loc_col_id+4]=image_in[(row_id+p)*WIDTH+col_id+4];
		loc_buffer[loc_row_id+p][loc_col_id+5]=image_in[(row_id+p)*WIDTH+col_id+5];
		loc_buffer[loc_row_id+p][loc_col_id+6]=image_in[(row_id+p)*WIDTH+col_id+6];
		loc_buffer[loc_row_id+p][loc_col_id+7]=image_in[(row_id+p)*WIDTH+col_id+7];
		
	}
	

	barrier(CLK_LOCAL_MEM_FENCE);


	//load in reg00
	image_reg[0][0] = (row_id==0||col_id==0)? 0 : ((loc_row_id==0||loc_col_id==0)? image_in[(row_id-1)*WIDTH+col_id-1]:loc_buffer[loc_row_id-1][loc_col_id-1]);

	//load in reg10	
	image_reg[1][0] = (col_id==0)? 0 : ((loc_col_id==0)? image_in[row_id*WIDTH+col_id-1]:loc_buffer[loc_row_id][loc_col_id-1]);

	//load in reg20
	image_reg[2][0] = (row_id==HEIGHT-1||col_id==0)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1||loc_col_id==0)? image_in[(row_id+1)*WIDTH+col_id-1]:loc_buffer[loc_row_id+1][loc_col_id-1]);

	
	//load in reg01
	image_reg[0][1] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id]:loc_buffer[loc_row_id-1][loc_col_id]);

	//load in reg11
	image_reg[1][1] = loc_buffer[loc_row_id][loc_col_id];

	//load in reg21
	image_reg[2][1] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)? image_in[(row_id+1)*WIDTH+col_id]:loc_buffer[loc_row_id+1][loc_col_id]);
	

	//load in reg02	
	image_reg[0][2] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+1]:loc_buffer[loc_row_id-1][loc_col_id+1]);

	//load in reg12
	image_reg[1][2] = loc_buffer[loc_row_id][loc_col_id+1];
	
	//load in reg22
	image_reg[2][2] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+1]:loc_buffer[loc_row_id+1][loc_col_id+1]);


	//load in reg03
	image_reg[0][3] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+1+1]:loc_buffer[loc_row_id-1][loc_col_id+1+1]);

	//load in reg13
	image_reg[1][3] = loc_buffer[loc_row_id][loc_col_id+1+1] ;
	
	//load in reg23
	image_reg[2][3] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+1+1]:loc_buffer[loc_row_id+1][loc_col_id+1+1]);


	//load in reg04
	image_reg[0][4] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+2+1]:loc_buffer[loc_row_id-1][loc_col_id+2+1]);

	//load in reg14
	image_reg[1][4] = loc_buffer[loc_row_id][loc_col_id+2+1];
	
	//load in reg24
	image_reg[2][4] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+2+1]:loc_buffer[loc_row_id+1][loc_col_id+2+1]);


	//load in reg05
	image_reg[0][5] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+3+1]:loc_buffer[loc_row_id-1][loc_col_id+3+1]);

	//load in reg15
	image_reg[1][5] = loc_buffer[loc_row_id][loc_col_id+3+1];
		
	//load in reg25
	image_reg[2][5] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+3+1]:loc_buffer[loc_row_id+1][loc_col_id+3+1]);


	//load in reg06
	image_reg[0][6] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+4+1]:loc_buffer[loc_row_id-1][loc_col_id+4+1]);

	//load in reg16
	image_reg[1][6] = loc_buffer[loc_row_id][loc_col_id+4+1];
		
	//load in reg26
	image_reg[2][6] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+4+1]:loc_buffer[loc_row_id+1][loc_col_id+4+1]);


	//load in reg07
	image_reg[0][7] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+5+1]:loc_buffer[loc_row_id-1][loc_col_id+5+1]);

	//load in reg17
	image_reg[1][7] = loc_buffer[loc_row_id][loc_col_id+5+1];
		
	//load in reg27
	image_reg[2][7] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+5+1]:loc_buffer[loc_row_id+1][loc_col_id+5+1]);

	
	//load in reg08
	image_reg[0][8] = (row_id==0)? 0 : ((loc_row_id==0)? image_in[(row_id-1)*WIDTH+col_id+6+1]:loc_buffer[loc_row_id-1][loc_col_id+6+1]);

	//load in reg18
	image_reg[1][8] = loc_buffer[loc_row_id][loc_col_id+6+1];
		
	//load in reg28
	image_reg[2][8] = (row_id==HEIGHT-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+1)*WIDTH+col_id+6+1]:loc_buffer[loc_row_id+1][loc_col_id+6+1]);

	//load in reg09
	image_reg[0][9] = (row_id==0||col_id+7==WIDTH-1)? 0 : ((loc_row_id==0||loc_col_id+7==BLOCKDIM_X*SIMD_X-1)? image_in[(row_id-1)*WIDTH+col_id+7+1]:loc_buffer[loc_row_id-1][loc_col_id+7+1]);

	//load in reg19
	image_reg[1][9] = (col_id+7==WIDTH-1)? 0 : ((loc_col_id+7==BLOCKDIM_X*SIMD_X-1)? image_in[row_id*WIDTH+col_id+7+1]:loc_buffer[loc_row_id][loc_col_id+7+1]);
		
	//load in reg29
	image_reg[2][9] = (row_id==HEIGHT-1||col_id+7==WIDTH-1)? 0 : ((loc_row_id==BLOCKDIM_Y*SUBDIM_Y-1||loc_col_id+7==BLOCKDIM_X*SIMD_X-1)?image_in[(row_id+1)*WIDTH+col_id+7+1]:loc_buffer[loc_row_id+1][loc_col_id+7+1]);


		for (p=0;p<SUBDIM_Y;p++)
		{
			//filter:
			resultx=(int8)(0,0,0,0,0,0,0,0);
			resulty=(int8)(0,0,0,0,0,0,0,0);
			#pragma unroll 3
			for (i=0;i<3;i++)
			{
				#pragma unroll 3
				for (j=0;j<3;j++)
				{
					pixel = (uint8)(image_reg[i][j],image_reg[i][j+1],image_reg[i][j+2],image_reg[i][j+3],
							image_reg[i][j+4],image_reg[i][j+5],image_reg[i][j+6],image_reg[i][j+7]);

					b.s0  = pixel.s0  & 0xff;
					b.s1  = pixel.s1  & 0xff;
					b.s2  = pixel.s2  & 0xff;
					b.s3  = pixel.s3  & 0xff;
					b.s4  = pixel.s4  & 0xff;
					b.s5  = pixel.s5  & 0xff;
					b.s6  = pixel.s6  & 0xff;
					b.s7  = pixel.s7  & 0xff;

					g.s0 = (pixel.s0 >> 8) & 0xff;
					g.s1 = (pixel.s1 >> 8) & 0xff;
					g.s2 = (pixel.s2 >> 8) & 0xff;
					g.s3 = (pixel.s3 >> 8) & 0xff;
					g.s4 = (pixel.s4 >> 8) & 0xff;
					g.s5 = (pixel.s5 >> 8) & 0xff;
					g.s6 = (pixel.s6 >> 8) & 0xff;
					g.s7 = (pixel.s7 >> 8) & 0xff;

					r.s0 = (pixel.s0 >> 16) & 0xff;
					r.s1 = (pixel.s1 >> 16) & 0xff;
					r.s2 = (pixel.s2 >> 16) & 0xff;
					r.s3 = (pixel.s3 >> 16) & 0xff;
					r.s4 = (pixel.s4 >> 16) & 0xff;
					r.s5 = (pixel.s5 >> 16) & 0xff;
					r.s6 = (pixel.s6 >> 16) & 0xff;
					r.s7 = (pixel.s7 >> 16) & 0xff;

					// RGB -> Luma conversion approximation
					// Avoiding floating point math operators greatly reduces
					// resource usage.
					luma.s0 = r.s0 * 66 + g.s0 * 129 + b.s0 * 25;
					luma.s1 = r.s1 * 66 + g.s1 * 129 + b.s1 * 25;
					luma.s2 = r.s2 * 66 + g.s2 * 129 + b.s2 * 25;
					luma.s3 = r.s3 * 66 + g.s3 * 129 + b.s3 * 25;
					luma.s4 = r.s4 * 66 + g.s4 * 129 + b.s4 * 25;
					luma.s5 = r.s5 * 66 + g.s5 * 129 + b.s5 * 25;
					luma.s6 = r.s6 * 66 + g.s6 * 129 + b.s6 * 25;
					luma.s7 = r.s7 * 66 + g.s7 * 129 + b.s7 * 25;

					luma.s0 = (luma.s0 + 128) >> 8;
					luma.s1 = (luma.s1 + 128) >> 8;
					luma.s2 = (luma.s2 + 128) >> 8;
					luma.s3 = (luma.s3 + 128) >> 8;
					luma.s4 = (luma.s4 + 128) >> 8;
					luma.s5 = (luma.s5 + 128) >> 8;
					luma.s6 = (luma.s6 + 128) >> 8;
					luma.s7 = (luma.s7 + 128) >> 8;

					luma.s0 =luma.s0 + 16;
					luma.s1 =luma.s1 + 16;
					luma.s2 =luma.s2 + 16;
					luma.s3 =luma.s3 + 16;
					luma.s4 =luma.s4 + 16;
					luma.s5 =luma.s5 + 16;
					luma.s6 =luma.s6 + 16;
					luma.s7 =luma.s7 + 16;

					resultx.s0=resultx.s0+wx[i][j]*luma.s0;
					resulty.s0=resulty.s0+wy[i][j]*luma.s0;

					resultx.s1=resultx.s1+wx[i][j]*luma.s1;
					resulty.s1=resulty.s1+wy[i][j]*luma.s1;

					resultx.s2=resultx.s2+wx[i][j]*luma.s2;
					resulty.s2=resulty.s2+wy[i][j]*luma.s2;

					resultx.s3=resultx.s3+wx[i][j]*luma.s3;
					resulty.s3=resulty.s3+wy[i][j]*luma.s3;

					resultx.s4=resultx.s4+wx[i][j]*luma.s4;
					resulty.s4=resulty.s4+wy[i][j]*luma.s4;

					resultx.s5=resultx.s5+wx[i][j]*luma.s5;
					resulty.s5=resulty.s5+wy[i][j]*luma.s5;

					resultx.s6=resultx.s6+wx[i][j]*luma.s6;
					resulty.s6=resulty.s6+wy[i][j]*luma.s6;

					resultx.s7=resultx.s7+wx[i][j]*luma.s7;
					resulty.s7=resulty.s7+wy[i][j]*luma.s7;
				}
			}
	
			temp.s0=abs(resultx.s0)+abs(resulty.s0);
            		temp.s1=abs(resultx.s1)+abs(resulty.s1);
			temp.s2=abs(resultx.s2)+abs(resulty.s2);
            		temp.s3=abs(resultx.s3)+abs(resulty.s3);
			temp.s4=abs(resultx.s4)+abs(resulty.s4);
            		temp.s5=abs(resultx.s5)+abs(resulty.s5);
			temp.s6=abs(resultx.s6)+abs(resulty.s6);
            		temp.s7=abs(resultx.s7)+abs(resulty.s7);
            
            		clamped.s0=temp.s0>32?1:0;
            		clamped.s1=temp.s1>32?1:0;
			clamped.s2=temp.s2>32?1:0;
            		clamped.s3=temp.s3>32?1:0;
			clamped.s4=temp.s4>32?1:0;
            		clamped.s5=temp.s5>32?1:0;
			clamped.s6=temp.s6>32?1:0;
            		clamped.s7=temp.s7>32?1:0;
			
			image_out[(row_id+p)*WIDTH+col_id]=clamped.s0;
			image_out[(row_id+p)*WIDTH+col_id+1]=clamped.s1;
			image_out[(row_id+p)*WIDTH+col_id+2]=clamped.s2;
			image_out[(row_id+p)*WIDTH+col_id+3]=clamped.s3;
			image_out[(row_id+p)*WIDTH+col_id+4]=clamped.s4;
			image_out[(row_id+p)*WIDTH+col_id+5]=clamped.s5;
			image_out[(row_id+p)*WIDTH+col_id+6]=clamped.s6;
			image_out[(row_id+p)*WIDTH+col_id+7]=clamped.s7;

			if (p+1<SUBDIM_Y)
			{
				//shift the reg row
				image_reg[0][0]=image_reg[1][0];
				image_reg[0][1]=image_reg[1][1];
				image_reg[0][2]=image_reg[1][2];
				image_reg[0][3]=image_reg[1][3];
				image_reg[0][4]=image_reg[1][4];
				image_reg[0][5]=image_reg[1][5];
				image_reg[0][6]=image_reg[1][6];
				image_reg[0][7]=image_reg[1][7];
				image_reg[0][8]=image_reg[1][8];
				image_reg[0][9]=image_reg[1][9];

				image_reg[1][0]=image_reg[2][0];
				image_reg[1][1]=image_reg[2][1];
				image_reg[1][2]=image_reg[2][2];
				image_reg[1][3]=image_reg[2][3];
				image_reg[1][4]=image_reg[2][4];
				image_reg[1][5]=image_reg[2][5];
				image_reg[1][6]=image_reg[2][6];
				image_reg[1][7]=image_reg[2][7];
				image_reg[1][8]=image_reg[2][8];
				image_reg[1][9]=image_reg[2][9];

				//load in reg20
				image_reg[2][0] = (row_id+p+1==HEIGHT-1||col_id==0)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1||loc_col_id==0)? image_in[(row_id+p+1+1)*WIDTH+col_id-1]:loc_buffer[loc_row_id+p+1+1][loc_col_id-1]);
			
				//load in reg21
				image_reg[2][1] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)? image_in[(row_id+p+1+1)*WIDTH+col_id]:loc_buffer[loc_row_id+p+1+1][loc_col_id]);
				
				//load in reg22
				image_reg[2][2] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+1]);

				//load in reg23
				image_reg[2][3] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+1+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+1+1]);

				//load in reg24
				image_reg[2][4] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+2+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+2+1]);

				//load in reg25
				image_reg[2][5] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+3+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+3+1]);

				//load in reg26
				image_reg[2][6] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+4+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+4+1]);

				//load in reg27
				image_reg[2][7] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+5+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+5+1]);

				//load in reg28
				image_reg[2][8] = (row_id+p+1==HEIGHT-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+6+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+6+1]);

				//load in reg29
				image_reg[2][9] = (row_id+p+1==HEIGHT-1||col_id+7==WIDTH-1)? 0 : ((loc_row_id+p+1==BLOCKDIM_Y*SUBDIM_Y-1||loc_col_id+7==BLOCKDIM_X*SIMD_X-1)?image_in[(row_id+p+1+1)*WIDTH+col_id+7+1]:loc_buffer[loc_row_id+p+1+1][loc_col_id+7+1]);


			}	

		}
}


// Copyright (C) 2013-2015 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.
