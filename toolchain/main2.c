
int k = 42;
int m;
int n;

int main()
{
	int x = 3;
	int y = 2;
	int z = x + y;
	k = z;
	
	extern unsigned int _sidata;
	m = _sidata;
	
	return k;
}
