package app.BoatNav;

import android.graphics.Bitmap;

public class BmpClass {
    public int inuse = 0;
    public int tilex = -1;
    public int tiley = -1;
    public Bitmap bm = null;

    public static BmpClass[] BmpClassSet(int size) {
    	BmpClass[] p= new BmpClass[size];
        for(int i=0; i<size; i++)
            p[i] = new BmpClass();
        return p;
    }
}
