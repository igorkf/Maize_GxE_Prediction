import time
import os
import random

import pandas as pd
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torch.optim.lr_scheduler import CyclicLR



class EDataset(Dataset):
    def __init__(self, df, y_filename):
        y = pd.read_csv(y_filename)
        self.df = df.merge(y, on=['Env', 'Hybrid'], how='left')
        self.features = df.columns.tolist()  # [x for x in self.df if 'svd' in x] + ['weather_station_lat', 'weather_station_lon']

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        return {
            'x': torch.tensor(self.df[self.features].iloc[idx], dtype=torch.float32),
            'y': torch.tensor(self.df['Yield_Mg_ha'].iloc[idx], dtype=torch.float32).unsqueeze(0)  # [1, 1]
            # 'Env': self.df['Env'].iloc[idx],
            # 'Hybrid': self.df['Hybrid'].iloc[idx]
        }


class EModel(nn.Module):
    def __init__(self, input_size, hidden_size, output_size):
        super(EModel, self).__init__()
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.fc2 = nn.Linear(hidden_size, output_size)
        self.dropout1 = nn.Dropout(p=0.4)

    def forward(self, x):
        x = torch.relu(self.fc1(x))
        x = self.dropout1(x)
        x = self.fc2(x)
        return x


def seed_everything(seed: int):
    random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed(seed)
    # torch.backends.cudnn.deterministic = True
    # torch.backends.cudnn.benchmark = True


def rmse_by_env(ypred, ytrue, env):
    pass
    


if __name__ == '__main__':

    start_time = time.perf_counter()

    seed_everything(42)

    # Standardize features
    xtrain = pd.read_csv('output/xtrain.csv').set_index(['Env', 'Hybrid'])
    xval = pd.read_csv('output/xval.csv').set_index(['Env', 'Hybrid'])
    xtest = pd.read_csv('output/xtest.csv').set_index(['Env', 'Hybrid'])
    for col in xtrain.columns:
        mean_ = xtrain[col].mean()
        std_ = xtrain[col].std()
        xtrain[col] = (xtrain[col] - mean_) / std_
        xval[col] = (xval[col] - mean_) / std_
        xtest[col] = (xtest[col] - mean_) / std_

    # Create an instance of the dataset
    train_dataset = EDataset(xtrain, 'output/ytrain.csv')

    # Create a dataloader to feed the data to the model
    train_dataloader = DataLoader(train_dataset, batch_size=32, shuffle=True)

    # The same for validation set
    val_dataset = EDataset(xval, 'output/yval.csv')
    val_dataloader = DataLoader(val_dataset, batch_size=32, shuffle=False)  # no shuffle here

    # Create an instance of the model
    input_size = len(train_dataset[0]['x'])
    hidden_size = 64
    output_size = 1
    num_epochs = 20
    LR = 0.001
    model = EModel(input_size, hidden_size, output_size)

    # Define the loss, optimizer, and learning rate scheduler
    # https://www.scaler.com/topics/pytorch/how-to-adjust-learning-rate-in-pytorch/
    criterion = nn.MSELoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=LR)
    scheduler = CyclicLR(
        optimizer, base_lr=LR, max_lr=0.1, step_size_up=2000, step_size_down=None,
         mode='triangular', gamma=1.0, scale_fn=None, scale_mode='cycle', cycle_momentum=False
    )

    # Train the model and evaluate
    for epoch in range(num_epochs):
        for batch in train_dataloader:
            xtrain = batch['x']
            ytrain = batch['y']

            # Forward pass
            ypred_train = model(xtrain)
            loss = criterion(ypred_train, ytrain) ** 0.5

            # Backward pass and optimization
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

        # Evaluate the model on the validation set
        model.eval()  # set the model to evaluation mode
        with torch.no_grad():  # temporarily set all the requires_grad flag to false
            val_loss = 0
            for batch in val_dataloader:
                xval = batch['x']
                yval = batch['y']

                # Forward pass
                ypred_val = model(xval)
                val_loss += (criterion(ypred_val, yval) ** 0.5).item()
            val_loss /= len(val_dataloader)
            scheduler.step()  # change lr

        last_lr = scheduler.get_last_lr()[0]
        print(f'Epoch: {epoch + 1}/{num_epochs}, LR: {last_lr:.6f}, RMSE (train): {loss.item():.4f}, RMSE (val): {val_loss:.4f}')
        model.train()  # set the model back to training mode

    end_time = time.perf_counter()
    total_time = (end_time - start_time) / 60
    print('Total minutes:', round(total_time, 2))

