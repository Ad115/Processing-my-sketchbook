class ChemicalField
{
  float[][] site, previous;
  int cols, rows;
  float cellSize, diffusionConstant;
  SourceDistribution sources;


  //.....................................................

  // CONSTRUCTOR

  ChemicalField(float cellSize, float diffusionConstant, SourceDistribution sources, SourceDistribution sinks)

  {
    this.cellSize = cellSize;
    rows = int(height/cellSize);
    cols = int(width/cellSize);

    if(diffusionConstant > 0)  {this.diffusionConstant = diffusionConstant; } // User proportionated
    else {this.diffusionConstant = (pow(cellSize/lengthUnit, 2) * timeUnit) / 8; } // Set diffussionConstant to the maximum

    this.sources = sources.init(rows, cols, SOURCE); // Initialize the sources
    this.sources .add (sinks.init(rows, cols, SINK)); // Add the sinks
    // Initialize grids
    site = new float[rows][cols];
    previous = new float[rows][cols];
    // Set grids to zero
    this.clear();
  }

  //.....................................................

  void clear()
  {  // Set grids to zero
    for(int i=0; i<rows; i++)
    { for (int j=0; j<cols; j++)
      { site[i][j] = 0;
        previous[i][j] = 0;
        if (sources.at(i, j) == SOURCE)  {  site[i][j] = sourceConcentration; }
      }
    }
  }

  //.....................................................

  void step()
  {
    // Save a snapshot of the current state
    this.saveStates();

    // Update the state of each cell
    float dt = 1/timeUnit;
    for (int i=0; i<rows; i++)
    { for(int j=0; j<cols; j++)
      { switch (sources.at(i, j))
        {  case SOURCE :  {  site[i][j] = sourceConcentration; }  break; // You are in the source
           case SINK   :  {  site[i][j] = 0; }  break; // You are in a sink
           default     :  {  site[i][j] = previous[i][j] + delta(i, j)*dt; } // Calculate the new value
        }
      }
    }
  }

  //.....................................................

  void saveStates()
  {
    for (int i=0; i<rows; i++)
    { for(int j=0; j<cols; j++)
      { previous[i][j] = site[i][j];
      }
    }
  }

  //.....................................................

  float delta(int i, int j)
  {
    float D = diffusionConstant;
    float delta = D*laplacian(i, j);
    return delta;
  }

  //.....................................................

  float laplacian(int i, int j)
  {
    int jj = (j+cols); // To apply modulus operator

    float local = previous[i][j];

    float differential = (previous[i][(jj+1) % cols] - local)
                         + (previous[i][(jj-1) % cols] - local);

    if (i-1 >= 0)  // Check if you are not in the top of the screen
      {  differential += (previous[i-1][j] - local)
                         + (previous[i-1][(jj-1) % cols] - local)
                         + (previous[i-1][(jj+1) % cols] - local);
      }

    if (i+1 < rows)  // Check if you are not in the bottom of the screen
      { differential += (previous[i+1][j] - local)
                         + (previous[i+1][(jj-1) % cols] - local)
                         + (previous[i+1][(jj+1) % cols] - local);
      }

    float h = cellSize / lengthUnit;
    float laplacian = differential / (h*h);
    return laplacian;
  }

  //.....................................................

  void draw()
  {
    noStroke();
    rectMode(CENTER);
    ellipseMode(CENTER);
    for (int i=0; i<rows; i++)
    { for (int j=0; j<cols; j++)
      { float concentration = site[i][j];
        float alpha = map(concentration, 0, sourceConcentration, 0, 255);
        // Check extreme cases
        if(concentration > sourceConcentration) { fill(alpha-255, alpha/100-255, 0, alpha);} // Turn gradually to yellow
        else if(concentration < 0)  { fill(0, 0, 255, abs(alpha)/100); } // Turn gradually to blue
        else  {fill(0, alpha); } // NORMAL: Fill with black color
        // Draw the cell
        float y = i*cellSize + cellSize/2;
        float x = j*cellSize + cellSize/2;
        if (drawEllipses)
        { float size = map(concentration, 0, sourceConcentration, cellSize, 2*cellSize);
          ellipse(x, y, size, size);
        }
        else
        { float size = cellSize;
          rect(x, y, size, size);
        }
        // Draw label with concentration
        if (labels)
        { fill(alpha/2);
          textSize(cellSize/2.3);
          float percentage = site[i][j]/sourceConcentration * 100;
          text(int(percentage), j*cellSize, y + 4);
        }
      }
    }
  }

  //.....................................................

  void reset(SourceDistribution sources, SourceDistribution sinks)
  {

    this.sources = sources.init(rows, cols, SOURCE); // Initialize the sources
    this.sources .add( sinks.init(rows, cols, SINK) ); // Add the sinks
  }
}
